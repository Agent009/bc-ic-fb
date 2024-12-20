import Array "mo:base/Array";
import Identity "../Identity";
import Log "../Log";
import Types "../Types";

module TxPortion {
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MODULE     DEFINITION   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public type TxPortion = {
        fund_id: Types.RecordId;
        tx_id: Types.RecordId;
        member_id: Types.RecordId;
        type1: Text;
        type2: ?Text;
        category: ?Text;
        amount: Float;
        date: ?Text;
        details: ?Text;
    };
    public type TxPortionRecord = Types.Record<TxPortion>;

    public func defaultRecords() : [TxPortionRecord] {
        return [];
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MANAGER       CLASS     ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public class Manager(fund_id: Types.RecordId, caller: Identity.Account, records: [TxPortionRecord]) = {
        //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
        //  REGION:    PARAMETERS   ----------   ----------   ----------   ----------   ----------   ----------
        //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
        
        // Aliases, abstractions and types
        type R = TxPortion.TxPortionRecord;
        type Account = Identity.Account;
        let debugPrefix = "Models -> TxPortionManager -> ";

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
        public func createRecord(record : TxPortion.TxPortion, id: Types.RecordId) : async R {
            let newRecord : R = {id = id; data = { record with fund_id = fund_id }};
            // TODO: Validation to ensure the following exist and belong to the specified fund.
            // From/to account, from/to pot, member_id
            // TODO: Validation to ensure type1/2/cat are correct.
            // TODO: Validation to ensure amount validates properly.
            logAndDebug(debug_show("createRecord -> newRecord -> fund", fund_id, "caller", caller, "newRecord", newRecord));
            return newRecord;
        };

        public func getRecord(id : Types.RecordId) : async ?R {
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
        public func updateRecord(id : Types.RecordId, updated : TxPortion.TxPortion) : async ?{ index: Nat; record: R } {
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
        public func deleteRecord(id : Types.RecordId) : async ?Types.RecordId {
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