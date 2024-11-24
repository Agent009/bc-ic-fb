import Array "mo:base/Array";
import Identity "../lib/Identity";
import Log "../lib/Log";
import Types "../lib/Types";

module Pot {
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MODULE     DEFINITION   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public type Pot = {
        fund_id: Types.RecordId;
        parent_pot_id: ?Nat;
        name: Text;
        name_leaf: ?Text;
        target_perc: Float;
        starting_balance: Float;
        starting_date: Text;
        value: Float;
        last_transaction_date: ?Text;
    };
    public type PotRecord = Types.Record<Pot>;

    public func defaultRecords() : [PotRecord] {
        return [
            // {
            //     id = 1; 
            //     data = {
            //         fund_id = 1; parent_pot_id = null; name = "Main Pot"; name_leaf = null;
            //         target_perc = 100.0; starting_balance = 1000.0; starting_date = "2022-01-01";
            //         value = 1000.0; last_transaction_date = null;
            //     }
            // }
        ];
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MANAGER       CLASS     ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public class Manager(fund_id: Nat, caller: Identity.Account, records: [PotRecord]) = {
        //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
        //  REGION:    PARAMETERS   ----------   ----------   ----------   ----------   ----------   ----------
        //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
        
        // Aliases, abstractions and types
        type R = Pot.PotRecord;
        type Account = Identity.Account;
        let debugPrefix = "Models -> PotManager -> ";

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

        // Send back the record to be created with the additional properties.
        // The caller should update the state variable with the new record.
        public func createRecord(record : Pot.Pot, id: Types.RecordId) : async R {
            let newRecord : R = {id = id; data = { record with fund_id = fund_id }};
            logAndDebug(debug_show("createRecord -> newRecord -> fund", fund_id, "caller", caller, "newRecord", newRecord));
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

        // Send back the index if the record can be updated.
        // The caller should update the state variable with the updated record.
        public func updateRecord(id : Nat, updated : Pot.Pot) : async ?{ index: Nat; record: R } {
            let fundRecords = await getForFund();
            let updatedRecord = { id = id; data = updated };
            let index = Array.indexOf<R>(updatedRecord, fundRecords, func(m1, m2) : Bool { m1.id == m2.id });
            logAndDebug(debug_show("updateRecord -> fund", fund_id, "caller", caller, "id", id, "updated", updated, "index", index));

            switch (index) {
                case (?i) {
                    return ?{ index = i; record = updatedRecord };
                };
                case null return null;
            };
        };

        // Send back the record ID if the record can be deleted.
        // The caller should remove the record to be deleted from the state variable.
        public func deleteRecord(id : Nat) : async ?Types.RecordId {
            // Find the record but only if it belongs to the account
            let record = Array.find<R>(records, func(m) { m.id == id and m.data.fund_id == fund_id });
            logAndDebug(debug_show("deleteRecord -> fund", fund_id, "caller", caller, "id", id, "records", records.size()));

            switch (record) {
                case null return null;
                case (?r) {
                    logAndDebug(debug_show("deleteRecord -> record to be deleted belong to account - go ahead with deletion"));
                    return ?r.id;
                }
            }
        };

        //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
        //  REGION:       MISC      ----------   ----------   ----------   ----------   ----------   ----------
        //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

        private func logAndDebug(message : Text) {
            Log.debugTs(debug_show(debugPrefix, message));
        };
    };
};