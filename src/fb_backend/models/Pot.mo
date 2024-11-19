import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Log "../lib/Log";
import Pot "../lib/Pot";

actor class Manager() {
    // Aliases, abstractions and types
    type R = Pot.PotRecord<Pot.Pot>;
    // Stable store
    stable var records : [R] = Pot.defaultRecords();
    stable var logsEntries : [(Time.Time, Text)] = [];
    // In-memory stores that we can utilise during canister operation. These will be saved to stable memory during upgrades.
    let logs = HashMap.fromIter<Time.Time, Text>(logsEntries.vals(), Iter.size(logsEntries.vals()), Int.equal, Int.hash);

    public func createRecord(record : R) : async R {
        let newRecord = { record with id = records.size() + 1 };
        logAndDebug("Models -> PotManager -> createRecord -> newRecord " # debug_show (newRecord));
        records := Array.append(records, [newRecord]);
        return newRecord;
    };

    public func getRecord(id : Nat) : async ?R {
        logAndDebug("Models -> PotManager -> getRecord -> id " # debug_show (id));
        return Array.find<R>(records, func(m) { m.id == id });
    };

    public func updateRecord(id : Nat, updated : R) : async ?R {
        let index = Array.indexOf<R>(updated, records, func(m1, m2) : Bool { m1.id == m2.id });
        logAndDebug("Models -> PotManager -> updateRecord -> id " # debug_show (id, "updated", updated, "index", index));
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
        let filtered = Array.filter<R>(records, func(m) { m.id != id });
        logAndDebug("Models -> PotManager -> deleteRecord -> id " # debug_show (id, "filtered", filtered, filtered.size(), records.size()));

        if (filtered.size() < records.size()) {
            records := filtered;
            return true;
        };

        return false;
    };

    public func getrecords() : async [R] {
        logAndDebug("Models -> PotManager -> getrecords -> records " # debug_show (records.size()));
        return records;
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:       MISC      ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public query func seeAllLogMessages() : async [(Time.Time, Text)] {
        logAndDebug("Models -> PotManager -> seeAllLogMessages");
        return Iter.toArray<(Time.Time, Text)>(logs.entries());
    };

    public func clearLogMessages() : async () {
        logAndDebug("Models -> PotManager -> clearLogMessages");

        for (key in logs.keys()) {
            logs.delete(key);
        };

        logsEntries := [];
    };

    private func logAndDebug(message : Text) {
        Log.logAndOrDebug(logs, message, true);
    };
}
