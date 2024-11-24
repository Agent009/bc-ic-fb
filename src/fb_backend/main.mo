import Array "mo:base/Array";
import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Error "mo:base/Error";
import Identity "lib/Identity";
import Fund "lib/model/Fund";
import Member "lib/model/Member";
import Pot "lib/model/Pot";
import Transaction "lib/model/Transaction";
import Log "lib/Log";
import Types "lib/Types";

// shared ({ caller = creator }) actor class fb(init : ?Types.InitPayload) = Self {
shared ({ caller = creator }) actor class fb() = Self {
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:    PARAMETERS   ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    // Aliases, abstractions and types
    type ID = Types.RecordId;
    type Account = Identity.Account;

    // Stable stores
    // private stable var members : Trie.Trie<Types.RecordId, Member.MemberRecord> = Trie.empty();
    // private stable var pots : Trie.Trie<Types.RecordId, Pot.PotRecord> = Trie.empty();
    private stable var nextFundId : Types.RecordId = 0;
    private stable var nextMemberId : Types.RecordId = 0;
    private stable var nextPotId : Types.RecordId = 0;
    private stable var nextTxId : Types.RecordId = 0;
    stable var funds : [Fund.FundRecord] = Fund.defaultRecords();
    stable var members : [Member.MemberRecord] = Member.defaultRecords();
    stable var pots : [Pot.PotRecord] = Pot.defaultRecords();
    stable var transactions : [Transaction.TransactionRecord] = Transaction.defaultRecords();
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
        nextFundId += 1;
        let newRecord = await manager.createRecord(record, nextFundId);
        // Commit the new record to the state.
        funds := Array.append(funds, [newRecord]);
        return newRecord;
    };

    public shared ({ caller }) func getFund(id: ID) : async ?Fund.FundRecord {
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
            logAndDebug(debug_show("FUNDS -> getFundsFor -> caller not creator, disallowed -> caller", caller, "creator", creator));
            throw Error.reject("Unauthorized");
        };

        let manager = Fund.Manager(account, funds);
        await manager.getRecords();
    };

    // dfx canister call fb_backend updateFund(1, record {data=record {creator=record {owner=principal "2vxsx-fae"; subaccount=null}; name="FB"; closing_date=null; start_date="2024-11-19"}})
    public shared ({ caller }) func updateFund(id: ID, updated: Fund.Fund) : async ?Fund.FundRecord {
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
    public shared ({ caller }) func deleteFund(id: ID) : async Bool {
        let manager = Fund.Manager(caller, funds);
        // Check if the record can be deleted. Will receive the record ID on success.
        let recordId = await manager.deleteRecord(id);

        switch (recordId) {
            case null return false;
            case (?id) {
                // Delete the record by removing it from the set data
                let updatedRecords = Array.filter<Fund.FundRecord>(funds, func(m) { m.id != id });
                funds := updatedRecords;
                logAndDebug(debug_show("FUNDS -> deleteRecord -> deleted record -> records", funds.size()));
                return true;
            }
        }
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MEMBERS       CRUD      ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public shared ({ caller }) func addMember(record: Member.Member, fund_id: ID) : async Member.MemberRecord {
        let manager = Member.Manager(fund_id, Identity.getAccountFromPrincipal(caller), members);
        // Check and receive the record to be added with additional properties.
        nextMemberId += 1;
        let newRecord = await manager.createRecord(record, nextMemberId);
        // Commit the new record to the state.
        members := Array.append(members, [newRecord]);
        return newRecord;
    };

    public shared ({ caller }) func getMember(id: ID, fund_id: ID) : async ?Member.MemberRecord {
        let manager = Member.Manager(fund_id, Identity.getAccountFromPrincipal(caller), members);
        await manager.getRecord(id);
    };

    public shared ({ caller }) func getMembers(fund_id: ID) : async [Member.MemberRecord] {
        let manager = Member.Manager(fund_id, Identity.getAccountFromPrincipal(caller), members);
        await manager.getRecords();
    };

    public shared ({ caller }) func updateMember(id: ID, updated: Member.Member, fund_id: ID) : async ?Member.MemberRecord {
        let manager = Member.Manager(fund_id, Identity.getAccountFromPrincipal(caller), members);
        // Check if the record can be updated. Will receive the index on success.
        let data = await manager.updateRecord(id, updated);
        let updatedRecords : [var Member.MemberRecord] = Array.thaw<Member.MemberRecord>(members);

        switch (data) {
            case (?d) {
                // Commit the updated record to the state.
                updatedRecords[d.index] := d.record;
                members := Array.freeze<Member.MemberRecord>(updatedRecords);
                return ?d.record;
            };
            case null return null;
        };
    };

    public shared ({ caller }) func deleteMember(id: ID, fund_id: ID) : async Bool {
        let manager = Member.Manager(fund_id, Identity.getAccountFromPrincipal(caller), members);
        // Check if the record can be deleted. Will receive the record ID on success.
        let recordId = await manager.deleteRecord(id);

        switch (recordId) {
            case null return false;
            case (?id) {
                // Delete the record by removing it from the set data
                let updatedRecords = Array.filter<Member.MemberRecord>(members, func(m) { m.id != id });
                members := updatedRecords;
                logAndDebug(debug_show("MEMBERS -> deleteRecord -> deleted record -> records", funds.size()));
                return true;
            }
        }
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:       POTS         CRUD      ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public shared ({ caller }) func addPot(record: Pot.Pot, fund_id: ID) : async Pot.PotRecord {
        let manager = Pot.Manager(fund_id, Identity.getAccountFromPrincipal(caller), pots);
        // Check and receive the record to be added with additional properties.
        nextPotId += 1;
        let newRecord = await manager.createRecord(record, nextPotId);
        // Commit the new record to the state.
        pots := Array.append(pots, [newRecord]);
        return newRecord;
    };

    public shared ({ caller }) func getPot(id: ID, fund_id: ID) : async ?Pot.PotRecord {
        let manager = Pot.Manager(fund_id, Identity.getAccountFromPrincipal(caller), pots);
        await manager.getRecord(id);
    };

    public shared ({ caller }) func getPots(fund_id: ID) : async [Pot.PotRecord] {
        let manager = Pot.Manager(fund_id, Identity.getAccountFromPrincipal(caller), pots);
        await manager.getRecords();
    };

    public shared ({ caller }) func updatePot(id: ID, updated: Pot.Pot, fund_id: ID) : async ?Pot.PotRecord {
        let manager = Pot.Manager(fund_id, Identity.getAccountFromPrincipal(caller), pots);
        // Check if the record can be updated. Will receive the index on success.
        let data = await manager.updateRecord(id, updated);
        let updatedRecords : [var Pot.PotRecord] = Array.thaw<Pot.PotRecord>(pots);

        switch (data) {
            case (?d) {
                // Commit the updated record to the state.
                updatedRecords[d.index] := d.record;
                pots := Array.freeze<Pot.PotRecord>(updatedRecords);
                return ?d.record;
            };
            case null return null;
        };
    };

    public shared ({ caller }) func deletePot(id: ID, fund_id: ID) : async Bool {
        let manager = Pot.Manager(fund_id, Identity.getAccountFromPrincipal(caller), pots);
        // Check if the record can be deleted. Will receive the record ID on success.
        let recordId = await manager.deleteRecord(id);

        switch (recordId) {
            case null return false;
            case (?id) {
                // Delete the record by removing it from the set data
                let updatedRecords = Array.filter<Pot.PotRecord>(pots, func(m) { m.id != id });
                pots := updatedRecords;
                logAndDebug(debug_show("POTS -> deleteRecord -> deleted record -> records", funds.size()));
                return true;
            }
        }
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:   TRANSACTIONS     CRUD      ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public shared ({ caller }) func addTransaction(record: Transaction.Transaction, fund_id: ID, member_id: ID) : async Transaction.TransactionRecord {
        let manager = Transaction.Manager(fund_id, Identity.getAccountFromPrincipal(caller), transactions);
        // Check and receive the record to be added with additional properties.
        nextTxId += 1;
        let newRecord = await manager.createRecord(record, nextTxId, member_id);
        // Commit the new record to the state.
        transactions := Array.append(transactions, [newRecord]);
        return newRecord;
    };

    public shared ({ caller }) func getTransaction(id: ID, fund_id: ID) : async ?Transaction.TransactionRecord {
        let manager = Transaction.Manager(fund_id, Identity.getAccountFromPrincipal(caller), transactions);
        await manager.getRecord(id);
    };

    public shared ({ caller }) func getTransactions(fund_id: ID) : async [Transaction.TransactionRecord] {
        let manager = Transaction.Manager(fund_id, Identity.getAccountFromPrincipal(caller), transactions);
        await manager.getRecords();
    };

    public shared ({ caller }) func updateTransaction(id: ID, updated: Transaction.Transaction, fund_id: ID) : async ?Transaction.TransactionRecord {
        let manager = Transaction.Manager(fund_id, Identity.getAccountFromPrincipal(caller), transactions);
        // Check if the record can be updated. Will receive the index on success.
        let data = await manager.updateRecord(id, updated);
        let updatedRecords : [var Transaction.TransactionRecord] = Array.thaw<Transaction.TransactionRecord>(transactions);

        switch (data) {
            case (?d) {
                // Commit the updated record to the state.
                updatedRecords[d.index] := d.record;
                transactions := Array.freeze<Transaction.TransactionRecord>(updatedRecords);
                return ?d.record;
            };
            case null return null;
        };
    };

    public shared ({ caller }) func deleteTransaction(id: ID, fund_id: ID) : async Bool {
        let manager = Transaction.Manager(fund_id, Identity.getAccountFromPrincipal(caller), transactions);
        // Check if the record can be deleted. Will receive the record ID on success.
        let recordId = await manager.deleteRecord(id);

        switch (recordId) {
            case null return false;
            case (?id) {
                // Delete the record by removing it from the set data
                let updatedRecords = Array.filter<Transaction.TransactionRecord>(transactions, func(m) { m.id != id });
                transactions := updatedRecords;
                logAndDebug(debug_show("TRANSACTIONS -> deleteRecord -> deleted record -> records", funds.size()));
                return true;
            }
        }
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
