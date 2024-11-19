import Identity "../lib/Identity";
import Types "../lib/Types";

module Member {
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
};
