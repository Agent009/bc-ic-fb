import Array "mo:base/Array";
import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Error "mo:base/Error";
import Identity "lib/Identity";
import Fund "lib/Fund";
import Member "lib/Member";
import Pot "lib/Pot";
import MemberManager "models/Member";
import PotManager "models/Pot";
import Log "lib/Log";

// shared ({ caller = creator }) actor class fb(init : ?Types.InitPayload) = Self {
shared ({ caller = creator }) actor class fb() = Self {
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:    PARAMETERS   ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    // Aliases, abstractions and types
    type Account = Identity.Account;

    // Stable stores
    // private stable var members : Trie.Trie<Types.RecordId, Member.MemberRecord> = Trie.empty();
    // private stable var pots : Trie.Trie<Types.RecordId, Pot.PotRecord> = Trie.empty();
    stable var funds : [Fund.FundRecord] = Fund.defaultRecords();
    stable var logsEntries : [(Time.Time, Text)] = [];

    // In-memory stores that we can utilise during canister operation. These will be saved to stable memory during upgrades.
    let debugPrefix = "Main -> ";
    let logs = HashMap.fromIter<Time.Time, Text>(logsEntries.vals(), Iter.size(logsEntries.vals()), Int.equal, Int.hash);

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:     UTILITY     ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    private func isCanisterCreator(caller: Principal) : Bool {
        return caller == creator;
    };

    public shared ({ caller }) func getMyPrincipal() : async Principal {
        return caller;
    };

    public func getCreatorPrincipal() : async Principal {
        return creator;
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      FUNDS         CRUD      ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    // dfx canister call fb_backend addFund(record {creator=record {owner=principal "7eevz-2ra7p-dsih3-3tyar-ve5rp-gfzj4-6oopo-7lno4-miffl-jj4mm-wqe"; subaccount=null}; name="Family Bank"; closing_date=null; start_date="2024-11-20"})
    public shared ({ caller }) func addFund(record: Fund.Fund) : async Fund.FundRecord {
        let manager = Fund.Manager(caller, funds);
        // Check and receive the record to be added with additional properties.
        let newRecord = await manager.createRecord(record);
        // Commit the new record to the state.
        funds := Array.append(funds, [newRecord]);
        return newRecord;
    };

    public shared ({ caller }) func getFund(id: Nat) : async ?Fund.FundRecord {
        let manager = Fund.Manager(caller, funds);
        await manager.getRecord(id);
    };

    public shared ({ caller }) func getFunds() : async [Fund.FundRecord] {
        let manager = Fund.Manager(caller, funds);
        await manager.getRecords();
    };

    // ADMIN function
    public shared ({ caller }) func getFundsFor(account: Principal) : async [Fund.FundRecord] {
        if (not isCanisterCreator(caller)) {
            logAndDebug(debug_show("getFundsFor -> caller not creator, disallowed -> caller", caller, "creator", creator));
            throw Error.reject("Unauthorized");
        };

        let manager = Fund.Manager(account, funds);
        await manager.getRecords();
    };

    // dfx canister call fb_backend updateFund(1, record {data=record {creator=record {owner=principal "2vxsx-fae"; subaccount=null}; name="FB"; closing_date=null; start_date="2024-11-19"}})
    public shared ({ caller }) func updateFund(id: Nat, updated: Fund.Fund) : async ?Fund.FundRecord {
        let manager = Fund.Manager(caller, funds);
        // Check if the record can be updated. Will receive the index on success.
        let data = await manager.updateRecord(id, updated);
        let updatedRecords : [var Fund.FundRecord] = Array.thaw<Fund.FundRecord>(funds);

        switch (data) {
            case (?d) {
                // Commit the updated record to the state.
                updatedRecords[d.index] := d.record;
                funds := Array.freeze<Fund.FundRecord>(updatedRecords);
                return ?d.record;
            };
            case null return null;
        };
    };

    // dfx canister call fb_backend deleteFund(1)
    public shared ({ caller }) func deleteFund(id: Nat) : async Bool {
        let manager = Fund.Manager(caller, funds);
        // Check if the record can be deleted. Will receive the record ID on success.
        let recordId = await manager.deleteRecord(id);

        switch (recordId) {
            case null return false;
            case (?id) {
                // Delete the record by removing it from the set data
                let updatedRecords = Array.filter<Fund.FundRecord>(funds, func(m) { m.id != id });
                funds := updatedRecords;
                logAndDebug(debug_show("deleteRecord -> deleted record -> records", funds.size()));
                return true;
            }
        }
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MEMBERS       CRUD      ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public shared ({ caller }) func addMember(record: Member.Member, fund_id: Nat) : async Member.MemberRecord {
        let manager = await MemberManager.Manager(fund_id, Identity.getAccountFromPrincipal(caller));
        await manager.createRecord(record);
    };

    public shared ({ caller }) func getMember(id: Nat, fund_id: Nat) : async ?Member.MemberRecord {
        let manager = await MemberManager.Manager(fund_id, Identity.getAccountFromPrincipal(caller));
        await manager.getRecord(id);
    };

    public shared ({ caller }) func getMembers(fund_id: Nat) : async [Member.MemberRecord] {
        let manager = await MemberManager.Manager(fund_id, Identity.getAccountFromPrincipal(caller));
        await manager.getRecords();
    };

    public shared ({ caller }) func updateMember(id: Nat, updated: Member.MemberRecord, fund_id: Nat) : async ?Member.MemberRecord {
        let manager = await MemberManager.Manager(fund_id, Identity.getAccountFromPrincipal(caller));
        await manager.updateRecord(id, updated);
    };

    public shared ({ caller }) func deleteMember(id: Nat, fund_id: Nat) : async Bool {
        let manager = await MemberManager.Manager(fund_id, Identity.getAccountFromPrincipal(caller));
        await manager.deleteRecord(id);
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:       POTS         CRUD      ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public shared ({ caller }) func addPot(record: Pot.Pot, fund_id: Nat) : async Pot.PotRecord {
        let manager = await PotManager.Manager(fund_id, Identity.getAccountFromPrincipal(caller));
        await manager.createRecord(record);
    };

    public shared ({ caller }) func getPot(id: Nat, fund_id: Nat) : async ?Pot.PotRecord {
        let manager = await PotManager.Manager(fund_id, Identity.getAccountFromPrincipal(caller));
        await manager.getRecord(id);
    };

    public shared ({ caller }) func getPots(fund_id: Nat) : async [Pot.PotRecord] {
        let manager = await PotManager.Manager(fund_id, Identity.getAccountFromPrincipal(caller));
        await manager.getRecords();
    };

    public shared ({ caller }) func updatePot(id: Nat, updated: Pot.PotRecord, fund_id: Nat) : async ?Pot.PotRecord {
        let manager = await PotManager.Manager(fund_id, Identity.getAccountFromPrincipal(caller));
        await manager.updateRecord(id, updated);
    };

    public shared ({ caller }) func deletePot(id: Nat, fund_id: Nat) : async Bool {
        let manager = await PotManager.Manager(fund_id, Identity.getAccountFromPrincipal(caller));
        await manager.deleteRecord(id);
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      CYCLES     MANAGEMENT   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public shared (_) func getCyclesAvailable() : async Nat {
        //logAndDebug(debug_show ("getCyclesAvailable -> msg", msg, "owner", owner));
        //assert (msg.caller == creator);
        logAndDebug(debug_show ("getCyclesAvailable ->", Cycles.available()));
        return Cycles.available()
    };

    public shared (_) func getCyclesBalance() : async Nat {
        //assert (msg.caller == creator);
        logAndDebug(debug_show ("getCyclesBalance ->", Cycles.balance()));
        return Cycles.balance()
    };

    public shared (_) func addCycles(amount : Nat) : async Nat {
        //assert (msg.caller == creator);
        let accepted = Cycles.accept<system>(amount);
        logAndDebug(debug_show ("addCycles -> amount", amount, "accepted", accepted));
        return accepted
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:       MISC      ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public query func seeAllLogMessages() : async [(Time.Time, Text)] {
        logAndDebug("seeAllLogMessages");
        return Iter.toArray<(Time.Time, Text)>(logs.entries())
    };

    public func clearLogMessages() : async () {
        logAndDebug("clearLogMessages");

        for (key in logs.keys()) {
            logs.delete(key)
        };

        logsEntries := []
    };

    private func logAndDebug(message : Text) {
        Log.logAndOrDebug(logs, debug_show(debugPrefix, message), true)
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:     UPGRADE     MANAGEMENT   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    // Extract the state in a stable type.
    if (logs.size() > 0) {
        logAndDebug(debug_show("UpgradeManagement -> setting stable logsEntries from unstable logs", logs.size(), Array.size(logsEntries)));
        logsEntries := Iter.toArray(logs.entries());
    };
}
