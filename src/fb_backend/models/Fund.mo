import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Identity "../lib/Identity";
import Log "../lib/Log";
import Fund "../lib/Fund";
import Types "../lib/Types";

actor class Manager(caller: Principal) = {
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:    PARAMETERS   ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    
    // Aliases, abstractions and types
    type R = Fund.FundRecord;
    type Account = Identity.Account;
    // Stable store
    private stable var nextRecordId : Types.RecordId = 0;
    stable var records : [R] = Fund.defaultRecords();
    stable var logsEntries : [(Time.Time, Text)] = [];
    // In-memory stores that we can utilise during canister operation. These will be saved to stable memory during upgrades.
    let debugPrefix = "Models -> FundManager -> ";
    let logs = HashMap.fromIter<Time.Time, Text>(logsEntries.vals(), Iter.size(logsEntries.vals()), Int.equal, Int.hash);
    let account : Identity.Account = Identity.getAccountFromPrincipal(caller);

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:     UTILITY     ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public func getForAccount() : async [R] {
        let filtered = Array.filter<R>(records, func(m) { Identity.accountsEqual(m.data.creator, account) });
        logAndDebug(debug_show("getForAccount -> account", account, "filtered", filtered.size(), " / ", records.size()));
        return filtered;
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:       CRUD      ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public func createRecord(record : Fund.Fund) : async R {
        let newRecord : R = {id = records.size() + 1; data = { record with creator = account }};
        logAndDebug(debug_show("createRecord -> newRecord -> account", account, "newRecord", newRecord));
        records := Array.append(records, [newRecord]);
        return newRecord;
    };

    public func getRecord(id : Nat) : async ?R {
        logAndDebug(debug_show("getRecord -> id", id));
        return Array.find<R>(await getForAccount(), func(m) { m.id == id });
    };

    public func getRecords() : async [R] {
        let accountRecords = await getForAccount();
        logAndDebug(debug_show("getrecords -> account", account, "filtered", accountRecords.size(), " / ", records.size()));
        return accountRecords;
    };

    public func updateRecord(id : Nat, updated : R) : async ?R {
        let accountRecords = await getForAccount();
        let index = Array.indexOf<R>(updated, accountRecords, func(m1, m2) : Bool { m1.id == m2.id });
        logAndDebug(debug_show("updateRecord -> id", id, "updated", updated, "index", index));
        let updatedRecords : [var R] = Array.thaw<R>(records);

        switch (index) {
            case (?i) {
                updatedRecords[i] := updated;
                let _ = Array.freeze<R>(updatedRecords);
                return ?updated;
            };
            case null return null;
        };
    };

    public func deleteRecord(id : Nat) : async Bool {
        // Find the record but only if it belongs to the account
        let record = Array.find<R>(records, func(m) { m.id == id and Identity.accountsEqual(m.data.creator, account) });
        logAndDebug(debug_show("deleteRecord -> id", id, "records", records.size()));

        switch (record) {
            case null return false;
            case (?r) {
                // Delete the record by removing it from the set data
                let newData = Array.filter<R>(records, func(m) { m.id != r.id });
                records := newData;
                logAndDebug(debug_show("deleteRecord -> deleted record belong to account -> records", records.size()));
                return true;
            }
        }
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:       MISC      ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public query func seeAllLogMessages() : async [(Time.Time, Text)] {
        logAndDebug("seeAllLogMessages");
        return Iter.toArray<(Time.Time, Text)>(logs.entries());
    };

    public func clearLogMessages() : async () {
        logAndDebug("clearLogMessages");

        for (key in logs.keys()) {
            logs.delete(key);
        };

        logsEntries := [];
    };

    private func logAndDebug(message : Text) {
        Log.logAndOrDebug(logs, debug_show(debugPrefix, message), true);
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:     UPGRADE     MANAGEMENT   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    // Upgrade management - extract the state in a stable type.
    if (logs.size() > 0) {
        Log.debugTs(debug_show("UpgradeManagement -> setting stable logsEntries from unstable logs", logs.size(), Array.size(logsEntries)));
        logsEntries := Iter.toArray(logs.entries());
    };

    if (nextRecordId < 1) {
        logAndDebug(debug_show("UpgradeManagement -> setting default records"));
        records := Fund.defaultRecords();
    };
};
