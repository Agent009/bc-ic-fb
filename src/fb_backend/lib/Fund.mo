import Array "mo:base/Array";
import Identity "../lib/Identity";
import Log "../lib/Log";
import Types "../lib/Types";

module Fund {
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MODULE     DEFINITION   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    // Aliases, abstractions and types
    public type Fund = {
        // The fund creator account
        creator: Identity.Account;
        // The fund name
        name: Text;
        // The date when the fund opened
        start_date: Text;
        // The date when the fund closed
        closing_date: ?Text;
    };
    public type FundRecord = Types.Record<Fund>;

    public func defaultRecords() : [FundRecord] {
        return [
            // {
            //     id = 1;
            //     data = {
            //         name = "Family Bank"; start_date = "2022-01-01"; closing_date = null
            //     }
            // }
        ];
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MANAGER       CLASS     ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public class Manager(caller: Principal, records: [FundRecord]) = {
        //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
        //  REGION:    PARAMETERS   ----------   ----------   ----------   ----------   ----------   ----------
        //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
        
        // Aliases, abstractions and types
        type R = Fund.FundRecord;
        type Account = Identity.Account;
        let debugPrefix = "Models -> FundManager -> ";
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

        // Send back the record to be created with the additional properties.
        // The caller should update the state variable with the new record.
        public func createRecord(record : Fund.Fund, id: Types.RecordId) : async R {
            let newRecord : R = {id = id; data = record}; //  data = { record with creator = account }
            logAndDebug(debug_show("createRecord -> newRecord -> account", account, "newRecord", newRecord));
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

        // Send back the index if the record can be updated.
        // The caller should update the state variable with the updated record.
        public func updateRecord(id : Nat, updated : Fund.Fund) : async ?{ index: Nat; record: R } {
            let accountRecords = await getForAccount();
            let updatedRecord = { id = id; data = updated };
            let index = Array.indexOf<R>(updatedRecord, accountRecords, func(m1, m2) : Bool { m1.id == m2.id });
            logAndDebug(debug_show("updateRecord -> id", id, "updated", updated, "index", index));

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
            let record = Array.find<R>(records, func(m) { m.id == id and Identity.accountsEqual(m.data.creator, account) });
            logAndDebug(debug_show("deleteRecord -> id", id, "records", records.size()));

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
