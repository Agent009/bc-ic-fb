import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Identity "../lib/Identity";
import Log "../lib/Log";
import Pot "../lib/Pot";
import Types "../lib/Types";

actor class Manager(fund_id: Nat, caller: Identity.Account) = {
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:    PARAMETERS   ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    // Aliases, abstractions and types
    type R = Pot.PotRecord;
    type Account = Identity.Account;
    // Stable store
    private stable var nextRecordId : Types.RecordId = 0;
    stable var records : [R] = Pot.defaultRecords();
    stable var logsEntries : [(Time.Time, Text)] = [];
    // In-memory stores that we can utilise during canister operation. These will be saved to stable memory during upgrades.
    let debugPrefix = "Models -> PotManager -> ";
    let logs = HashMap.fromIter<Time.Time, Text>(logsEntries.vals(), Iter.size(logsEntries.vals()), Int.equal, Int.hash);

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:     UTILITY     ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public func getForFund() : async [R] {
        let filtered = Array.filter<R>(records, func(m) { m.data.fund_id == fund_id });
        logAndDebug(debug_show("getForFund -> fund", fund_id, "filtered", filtered.size(), " / ", records.size()));
        return filtered;
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:       CRUD      ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public func createRecord(record : Pot.Pot) : async R {
        let newRecord : R = {id = records.size() + 1; data = { record with fund_id = fund_id }};
        logAndDebug(debug_show("createRecord -> newRecord -> fund", fund_id, "caller", caller, "newRecord", newRecord));
        records := Array.append(records, [newRecord]);
        return newRecord;
    };

    public func getRecord(id : Nat) : async ?R {
        logAndDebug(debug_show("getRecord -> fund", fund_id, "id", id));
        return Array.find<R>(await getForFund(), func(m) { m.id == id });
    };

    public func getRecords() : async [R] {
        let fundRecords = await getForFund();
        logAndDebug(debug_show("getrecords -> fund", fund_id, "filtered", fundRecords.size(), " / ", records.size()));
        return fundRecords;
    };

    // TODO: Implement access control.
    // Head and fund manager should be able to update all records within their own funds.
    // The rest should not be able to directly update pots.
    public func updateRecord(id : Nat, updated : R) : async ?R {
        let fundRecords = await getForFund();
        let index = Array.indexOf<R>(updated, fundRecords, func(m1, m2) : Bool { m1.id == m2.id });
        logAndDebug(debug_show("updateRecord -> fund", fund_id, "caller", caller, "id", id, "updated", updated, "index", index));
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

    // TODO: Implement access control.
    public func deleteRecord(id : Nat) : async Bool {
        // Find the record but only if it belongs to the account
        let record = Array.find<R>(records, func(m) { m.id == id and m.data.fund_id == fund_id });
        logAndDebug(debug_show("deleteRecord -> fund", fund_id, "caller", caller, "id", id, "records", records.size()));

        switch (record) {
            case null return false;
            case (?r) {
                // Delete the record by removing it from the set data
                let newData = Array.filter<R>(records, func(m) { m.id != r.id });
                records := newData;
                logAndDebug(debug_show("deleteRecord -> deleted record belong to fund -> records", records.size()));
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
        logAndDebug(debug_show("UpgradeManagement -> setting stable logsEntries from unstable logs", logs.size(), Array.size(logsEntries)));
        logsEntries := Iter.toArray(logs.entries());
    };

    if (nextRecordId < 1) {
        logAndDebug(debug_show("UpgradeManagement -> setting default records"));
        records := Pot.defaultRecords();
    };
}
