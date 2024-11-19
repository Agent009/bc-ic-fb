import Array "mo:base/Array";
import Option "mo:base/Option";
import Log "../lib/Log";
import Generics "mo:generics";
import Types "../lib/Types";

// The intention was to mimic usage of generics and base classes as in other programming languages
// to simplify the CRUD logic, but this has become way too complex, so it's not in use at the moment.
module Manager {
    type R<T> = Types.Record<T>;

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:       CRUD      ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    // Asynchronous generics in Motoko workaround
    // https://motokodefi.substack.com/p/asynchronous-generics-in-motoko
    public class init_<T>(model : Text, records : [R<T>]) {
        let buf = Generics.Buf<[R<T>]>();

        // Asynchronous generics in Motoko workaround
        // https://motokodefi.substack.com/p/asynchronous-generics-in-motoko
        // Create a new record
        public func createRecord_c(record : R<T>) : async* () {
            let newRecord = { record with id = records.size() + 1 };
            Log.debugTs(debug_show (model, "-> createRecord_c -> newRecord", newRecord.id));
            // records := Array.append(records, [newRecord]);
            buf.set([record]);
            // return newRecord;
        };

        public func createRecord_r() : R<T> = buf.get()[0];

        // Get an existing record
        public func getRecord_c(id : Nat) : async* ?() {
            Log.debugTs(debug_show (model, "-> getRecord_c -> id", id));
            let record = Array.find<R<T>>(records, func(m : R<T>) { m.id == id });

            switch (record) {
                case (?r) {
                    Option.make(buf.set([r]));
                };
                case (null) { return null };
            };
        };

        public func getRecord_r() : ?R<T> = switch (Array.size(buf.get())) {
            case (0) { return null };
            case (_) { return Option.make<R<T>>(buf.get()[0]) };
        };

        // Get all records
        public func getRecords_c() : async* () {
            Log.debugTs(debug_show (model, "-> getRecords_c -> records", records.size()));
            buf.set(records);
        };

        public func getRecords_r() : [R<T>] = buf.get();

        // Update an existing record
        public func updateRecord_c(id : Nat, updated : R<T>) : async* ?() {
            let index = Array.indexOf<R<T>>(updated, records, func(m1, m2) : Bool { m1.id == m2.id });
            Log.debugTs(debug_show (model, "-> updateRecord_c -> id", id, "index", index));
            // let updatedRecords : [var R<T>] = Array.thaw<R<T>>(records);

            switch (index) {
                case (?_) {
                    // updatedRecords[i] := updated;
                    // let _ = Array.freeze<R<T>>(updatedRecords);
                    // return ?updated;
                    Option.make(buf.set([updated]));
                };
                case null return null;
            };
        };

        public func updateRecord_r() : ?R<T> = switch (Array.size(buf.get())) {
            case (0) { return null };
            case (_) { return Option.make<R<T>>(buf.get()[0]) };
        };

        // Delete an existing record
        // Returns the new records array which should be processed accordingly and set to stable stores if necessary.
        public func deleteRecord_c(id : Nat) : async* () {
            let filtered = Array.filter<R<T>>(records, func(m) { m.id != id });
            Log.debugTs(debug_show (model, "-> deleteRecord_c -> id", id, filtered.size(), records.size()));

            if (filtered.size() < records.size()) {
                // records := filtered;
                // return true;
                buf.set(filtered);
            };

            // return false;
            buf.set(records);
        };

        public func deleteRecord_r() : [R<T>] = buf.get();
    };
};
