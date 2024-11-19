import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Error "mo:base/Error";
import Identity "lib/Identity";
import Fund "lib/Fund";
import Member "lib/Member";
import Pot "lib/Pot";
import FundManager "models/Fund";
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
    //  REGION:       FUNDS     ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public shared ({ caller }) func addFund(record: Fund.Fund) : async Fund.FundRecord {
        let manager = await FundManager.Manager(caller);
        await manager.createRecord(record);
    };

    public shared ({ caller }) func getFund(id: Nat) : async ?Fund.FundRecord {
        let manager = await FundManager.Manager(caller);
        await manager.getRecord(id);
    };

    public shared ({ caller }) func getFunds() : async [Fund.FundRecord] {
        let manager = await FundManager.Manager(caller);
        await manager.getRecords();
    };

    // ADMIN function
    public shared ({ caller }) func getFundsFor(account: Principal) : async [Fund.FundRecord] {
        if (not isCanisterCreator(caller)) {
            logAndDebug(debug_show("getFundsFor -> caller not creator, disallowed -> caller", caller, "creator", creator));
            throw Error.reject("Unauthorized");
        };

        let manager = await FundManager.Manager(account);
        await manager.getRecords();
    };

    public shared ({ caller }) func updateFund(id: Nat, updated: Fund.FundRecord) : async ?Fund.FundRecord {
        let manager = await FundManager.Manager(caller);
        await manager.updateRecord(id, updated);
    };

    public shared ({ caller }) func deleteFund(id: Nat) : async Bool {
        let manager = await FundManager.Manager(caller);
        await manager.deleteRecord(id);
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MEMBERS    ----------   ----------   ----------   ----------   ----------   ----------
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
    //  REGION:       POTS      ----------   ----------   ----------   ----------   ----------   ----------
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
