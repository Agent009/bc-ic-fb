//region Constants
const today = new Date();
const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
//endregion

/**
 * Manage date and time.
 */
export default class DateManager {
    //region Class fields
    #_date;
    #_timestamp;
    #_year;
    #_month;
    #_day;
    #_dayName;
    #_hour;
    #_minute;
    #_second;
    #_millisecond;
    #_tzOffset;
    #_isoString;
    #_dateString;
    #_timeString;
    #_ukDateString;
    //endregion

    //region Core
    /**
     * @param milliseconds number The epoch timestamp.
     */
    constructor(milliseconds) {
        this.#_date = new Date(milliseconds !== undefined ? milliseconds : Date.now() );
        this.createDateComponents();
    }

    /**
     * Update the date object.
     * This will automatically call createDateComponents() when set date() is called.
     */
    updateDate() {
        this.date = new Date(this.year, this.month, this.day, this.hour, this.minute, this.second, this.millisecond);
    }

    /**
     * Create / update the date components when the date object is updated.
     * @return {DateManager}
     */
    createDateComponents() {
        this.#_timestamp = this.date.getTime();
        this.#_year = this.date.getFullYear();
        this.#_month = this.date.getMonth();
        // A number between 1 - 31
        this.#_day = this.date.getDate();
        this.#_dayName = days[this.date.getDay()];
        // A number between 0 - 23
        this.#_hour = this.date.getHours();
        // A number between 0 - 59
        this.#_minute = this.date.getMinutes();
        // A number between 0 - 59
        this.#_second = this.date.getSeconds();
        // A number between 0 - 999
        this.#_millisecond = this.date.getMilliseconds();
        // The number of minutes returned by getTimezoneOffset() is positive if the local time zone is behind UTC,
        // and negative if the local time zone is ahead of UTC.
        this.#_tzOffset = this.date.getTimezoneOffset();
        // 24 or 27 characters long (YYYY-MM-DDTHH:mm:ss.sssZ or ±YYYYYY-MM-DDTHH:mm:ss.sssZ, respectively)
        // The timezone is always zero UTC offset
        // E.g. "2011-10-05T14:48:00.000Z"
        this.#_isoString = this.date.toISOString();
        // E.g. "Wed Jul 28 1993"
        this.#_dateString = this.date.toDateString();
        // E.g. "15:04:18"
        this.#_timeString = this.date.toLocaleTimeString();
        const localeOptions = {weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'};
        this.#_ukDateString = this.date.toLocaleDateString('en-GB', localeOptions);
        return this;
    }

    /**
     * Adjust the milliseconds value.
     * @param val number
     * @return {DateManager}
     */
    adjustMilliseconds(val) {
        return this.adjustDate("milliseconds", val);
    }

    /**
     * Adjust the seconds value.
     * @param val number
     * @return {DateManager}
     */
    adjustSeconds(val) {
        return this.adjustDate("seconds", val);
    }

    /**
     * Adjust the minutes value.
     * @param val number
     * @return {DateManager}
     */
    adjustMinutes(val) {
        return this.adjustDate("minutes", val);
    }

    /**
     * Adjust the hours value.
     * @param val number
     * @return {DateManager}
     */
    adjustHours(val) {
        return this.adjustDate("hours", val);
    }

    /**
     * Adjust the days value.
     * @param val number
     * @return {DateManager}
     */
    adjustDays(val) {
        return this.adjustDate("days", val);
    }

    /**
     * Adjust the months value.
     * @param val number
     * @return {DateManager}
     */
    adjustMonths(val) {
        return this.adjustDate("months", val);
    }

    /**
     * Adjust the years value.
     * @param val number
     * @return {DateManager}
     */
    adjustYears(val) {
        return this.adjustDate("years", val);
    }

    /**
     * Adjust the specified period value.
     * @param type string
     * @param val number
     * @return {DateManager}
     */
    adjustDate(type, val) {
        switch (type) {
            case "milliseconds":
                this.millisecond += val;
                break;
            case "seconds":
                this.second += val;
                break;
            case "minutes":
                this.minute += val;
                break;
            case "hours":
                this.hour += val;
                break;
            case "days":
                this.day += val;
                break;
            case "months":
                this.month += val;
                break;
            case "years":
                this.year += val;
                break;
            default:
                break;
        }

        return this;
    }
    //endregion

    //region Getters and setters
    /**
     * @returns Date
     */
    get date() {
        return this.#_date;
    }

    /**
     * @param val Date
     */
    set date(val) {
        this.#_date = val;
        this.createDateComponents();
    }

    /**
     * @returns number
     */
    get timestamp() {
        return this.#_timestamp;
    }

    /**
     * @param val number
     */
    set timestamp(val) {
        this.#_timestamp = val;
        this.date = new Date(this.timestamp);
    }

    /**
     * @returns number
     */
    get year() {
        return this.#_year;
    }

    /**
     * @param val number
     */
    set year(val) {
        this.#_year = val;
        this.updateDate();
    }

    /**
     * @returns number
     */
    get month() {
        return this.#_month;
    }

    /**
     * @param val number
     */
    set month(val) {
        this.#_month = val;
        this.updateDate();
    }

    /**
     * @returns number
     */
    get day() {
        return this.#_day;
    }

    /**
     * @param val number
     */
    set day(val) {
        this.#_day = val;
        this.updateDate();
    }

    /**
     * @returns string
     */
    get dayName() {
        return this.#_dayName;
    }

    /**
     * @returns number
     */
    get hour() {
        return this.#_hour;
    }

    /**
     * @param val number
     */
    set hour(val) {
        this.#_hour = val;
        this.updateDate();
    }

    /**
     * @returns number
     */
    get minute() {
        return this.#_minute;
    }

    /**
     * @param val number
     */
    set minute(val) {
        this.#_minute = val;
        this.updateDate();
    }

    /**
     * @returns number
     */
    get second() {
        return this.#_second;
    }

    /**
     * @param val number
     */
    set second(val) {
        this.#_second = val;
        this.updateDate();
    }

    /**
     * @returns number
     */
    get millisecond() {
        return this.#_millisecond;
    }

    /**
     * @param val number
     */
    set millisecond(val) {
        this.#_millisecond = val;
        this.updateDate();
    }

    /**
     * @returns number
     */
    get tzOffset() {
        return this.#_tzOffset;
    }

    /**
     * @param val number
     */
    set tzOffset(val) {
        this.#_minute += val;
        this.updateDate();
    }

    /**
     * @returns string
     */
    get isoString() {
        return this.#_isoString;
    }

    /**
     * @returns string
     */
    get dateString() {
        return this.#_dateString;
    }

    /**
     * @returns string
     */
    get timeString() {
        return this.#_timeString;
    }

    /**
     * @returns string
     */
    get ukDateString() {
        return this.#_ukDateString;
    }
    //endregion

    //region Misc.
    /**
     * Return a clone object
     * @returns {DateManager}
     */
    clone() {
        return new DateManager(this.timestamp);
    }
    //endregion
}

//region Utilities
export function getDate() {
    return today;
}
//endregion
