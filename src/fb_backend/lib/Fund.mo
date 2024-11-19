import Identity "../lib/Identity";
import Types "../lib/Types";

module Fund {
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
};
