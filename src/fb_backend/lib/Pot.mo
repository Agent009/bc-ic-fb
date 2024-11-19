import Identity "../lib/Identity";
import Types "../lib/Types";

module Pot {
    public type Pot = {
        account: ?Identity.Account;
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
            //         parent_pot_id = null; name = "Main Pot"; name_leaf = null;
            //         target_perc = 100.0; starting_balance = 1000.0; starting_date = "2022-01-01";
            //         value = 1000.0; last_transaction_date = null;
            //     }
            // }
        ];
    };
};