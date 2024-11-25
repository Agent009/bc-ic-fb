import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";

module Identity {
    public type Subaccount = Blob;
    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
    };

    public func getDefaultSubaccount() : Subaccount {
        Blob.fromArrayMut(Array.init(32, 0 : Nat8));
    };

    public func getAccountFromPrincipal(principal : Principal) : Account {
        return {
            owner = principal;
            subaccount = Option.make(getDefaultSubaccount());
        };
    };

    public func getAccount(principal : Principal, subaccount: Subaccount) : Account {
        return {
            owner = principal;
            subaccount = Option.make(subaccount);
        };
    };

    // Returns the the total number of tokens on all accounts.
    public func totalClaimedSupply(ledger : TrieMap.TrieMap<Account, Nat>) : Nat {
        var claimed : Nat = 0;

        for ((account, balance) in ledger.entries()) {
            claimed += balance;
        };

        Debug.print("Total claimed supply " # debug_show(claimed));
        return claimed;
    };

    public func accountsEqual(lhs : Account, rhs : Account) : Bool {
        // Debug.print("accountsEqual() - lhs " # debug_show(lhs) # ", rhs " # debug_show(rhs));
        let lhsSubaccount : Subaccount = Option.get<Subaccount>(lhs.subaccount, getDefaultSubaccount());
        // Debug.print("lhsSubaccount " # debug_show(lhsSubaccount));
        let rhsSubaccount : Subaccount = Option.get<Subaccount>(rhs.subaccount, getDefaultSubaccount());
        // Debug.print("rhsSubaccount " # debug_show(rhsSubaccount));
        Principal.equal(lhs.owner, rhs.owner) and Blob.equal(lhsSubaccount, rhsSubaccount);
    };

    public func accountsHash(lhs : Account) : Nat32 {
         let lhsSubaccount : Subaccount = Option.get<Subaccount>(lhs.subaccount, getDefaultSubaccount());
        let hashSum = Nat.add(Nat32.toNat(Principal.hash(lhs.owner)), Nat32.toNat(Blob.hash(lhsSubaccount)));
        Nat32.fromNat(hashSum % (2**32 - 1));
    };

    public func accountBelongToPrincipal(account : Account, principal : Principal) : Bool {
        Principal.equal(account.owner, principal);
    };
};
