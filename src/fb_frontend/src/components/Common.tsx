import React, {useState} from 'react';
import HighlightIcon from '@mui/icons-material/Highlight';
import logoUrl from "../../public/logo2.svg";
import DateManager from '@lib/dateUtils.js';

// const dm = new DateManager(Date.now());
// let dmTomorrow = dm.clone().adjustDays(1).ukDateString

export function Header() {
    const [time, setTime] = useState(new DateManager(Date.now()));
    setInterval(() => setTime(new DateManager(Date.now())), 1000);
    return (
        <header className="App-header">
            💎
            {/*<img src={logo} className="App-logo" alt="logo" height="200" />*/}
            <HighlightIcon />
            <p>
                {/*Today: {dm.ukDateString}, Tomorrow: {dmTomorrow}*/}
                Today: {time.ukDateString}, Time: {time.timeString}
            </p>
        </header>
    );
}

export function Footer() {
    return (
        <footer className="App-footer">
            {/*<Logo />*/}
            <img src={logoUrl} className="App-logo" alt="logo" height="200"/>
            <p>Copyright ⓒ {new DateManager(Date.now()).year}</p>
        </footer>
    );
}

export default function Body() {
    return (
        <div id="App-body">

        </div>
    );
};
