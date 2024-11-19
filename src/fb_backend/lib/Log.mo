import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Debug "mo:base/Debug";

module Log {
    public func log(logs : HashMap.HashMap<Time.Time, Text>, message : Text) {
        logAndOrDebug(logs, message, false);
    };

    public func logAndDebug(logs : HashMap.HashMap<Time.Time, Text>, message : Text) {
        logAndOrDebug(logs, message, true);
    };

    public func logAndOrDebug(logs : HashMap.HashMap<Time.Time, Text>, message : Text, dPrint : Bool) {
        logs.put(Time.now(), message);

        if (dPrint) {
            Debug.print(message);
        };
    };

    public func debugTs(message : Text) {
        Debug.print(debug_show(Time.now()) # message);
    };
};
