import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Identity "lib/Identity";
import Member "lib/Member";
import MemberManager "models/Member";
// import PotManager "models/Pot";
// import Transaction "models/Transaction";
import Log "lib/Log";
import Types "lib/Types";

shared ({ caller = creator }) actor class fb(init : ?Types.InitPayload) = Self {
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:    PARAMETERS   ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    // Aliases, abstractions and types
    type Account = Identity.Account;

    // Stable stores
    // private stable var nextMemberId : Types.RecordId = 0;
    private stable var nextPotId : Types.RecordId = 0;
    // private stable var members : Trie.Trie<Types.RecordId, Member.MemberRecord> = Trie.empty();
    // private stable var pots : Trie.Trie<Types.RecordId, Pot.PotRecord> = Trie.empty();
    stable var logsEntries : [(Time.Time, Text)] = [];
    // stable let accountManager = Account.Manager();
    // stable let transactionManager = Transaction.Manager();

    // In-memory stores that we can utilise during canister operation. These will be saved to stable memory during upgrades.
    let debugPrefix = "Main -> ";
    let logs = HashMap.fromIter<Time.Time, Text>(logsEntries.vals(), Iter.size(logsEntries.vals()), Int.equal, Int.hash);

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MEMBERS    ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public func addMember(record: Member.MemberRecord, account: Identity.Account) : async Member.MemberRecord {
        let manager = await MemberManager.Manager(account);
        await manager.createRecord(record);
    };

    public func getMember(id: Nat, account: Identity.Account) : async ?Member.MemberRecord {
        let manager = await MemberManager.Manager(account);
        await manager.getRecord(id);
    };

    public func getMembers(account: Identity.Account) : async [Member.MemberRecord] {
        let manager = await MemberManager.Manager(account);
        await manager.getRecords();
    };

    public func updateMember(id: Nat, updated: Member.MemberRecord, account: Identity.Account) : async ?Member.MemberRecord {
        let manager = await MemberManager.Manager(account);
        await manager.updateRecord(id, updated);
    };

    public func deleteMember(id: Nat, account: Identity.Account) : async Bool {
        let manager = await MemberManager.Manager(account);
        await manager.deleteRecord(id);
    };

    // public func initPots() : async () {
    //     await potManager.initDefaults();
    // };

    // public func initAccounts() : async () {
    //     await accountManager.initDefaults(memberManager.getMembers());
    // };

    // public func initTransactions() : async () {
    //     await transactionManager.initDefaults();
    // };

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

    // if (nextMemberId < 1) {
    //     members := Member.defaultRecords();
    // };
}
