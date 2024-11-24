import Array "mo:base/Array";
import Identity "../lib/Identity";
import Log "../lib/Log";
import Types "../lib/Types";

module Member {
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MODULE     DEFINITION   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public type Member = {
        fund_id: Types.RecordId;
        account: Identity.Account;
        name: Text;
        abbreviation: Text;
        family: Text;
        // TODO: Implement access control with regards to fund actions.
        // https://internetcomputer.org/docs/current/tutorials/developer-journey/level-3/3.6-motoko-lvl3/#principals-and-caller-identification
        role: Text;
        join_date: Text;
        leave_date: ?Text;
        expected_monthly_deposit: ?Float;
    };
    public type MemberRecord = Types.Record<Member>;

    public func defaultRecords() : [MemberRecord] {
        return [
            // {
            //     id = 1;
            //     data = {
            //         fund_id = 1; name = "Abida Parveen"; abbreviation = "AP"; family = "Abida Family";
            //         role = "Head"; join_date = "2022-01-01"; leave_date = null; expected_monthly_deposit = ?50.0
            //     }
            // },
            // {
            //     id = 2; 
            //     data = {
            //         fund_id = 1; name = "Mohammad Amir"; abbreviation = "MA"; family = "Amir Family";
            //         role = "Head"; join_date = "2022-01-01"; leave_date = null; expected_monthly_deposit = ?300.0
            //     }
            // },
            // {
            //     id = 3; 
            //     data = {
            //         fund_id = 1; name = "Sonia Amir"; abbreviation = "SA"; family = "Amir Family";
            //         role = "Participant"; join_date = "2022-01-01"; leave_date = null; expected_monthly_deposit = ?50.0
            //     }
            // }
        ];
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      MANAGER       CLASS     ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public class Manager(fund_id: Nat, caller: Identity.Account, records: [MemberRecord]) = {
        //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
        //  REGION:    PARAMETERS   ----------   ----------   ----------   ----------   ----------   ----------
        //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
        
        // Aliases, abstractions and types
        type R = Member.MemberRecord;
        type Account = Identity.Account;
        let debugPrefix = "Models -> MemberManager -> ";

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
        public func createRecord(record : Member.Member, id: Types.RecordId) : async R {
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
        public func updateRecord(id : Nat, updated : Member.Member) : async ?{ index: Nat; record: R } {
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
