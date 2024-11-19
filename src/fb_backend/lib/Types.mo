module Types {
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      GENERIC    ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:     ACCOUNTS    ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public let DEFAULT_PRINCIPAL = "jxic7-kzwkr-4kcyk-2yql7-uqsrg-lvrzb-k7avx-e4nbh-nfmli-rddvs-mqe";

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:      RECORDS    ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public type RecordId = Nat;
    public type Record<T> = {
        id: RecordId;
        data: T
    };

    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------
    //  REGION:    BOOTSTRAP    ----------   ----------   ----------   ----------   ----------   ----------
    //----------   ----------   ----------   ----------   ----------   ----------   ----------   ----------

    public type UpdateSystemParamsPayload = {};
    public type InitPayload = {};
}