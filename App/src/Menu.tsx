import React from 'react';
import { BrowserRouter as Router, Route, Link, Routes } from 'react-router-dom';



const Screensaver: React.FC = () => {
    return (
        <>
        <div>
            <h1>Settings Menu</h1>
            <ul>
                <li><Link to="/settings/face">Face</Link></li>
                <li><Link to="/settings/sound">Sound</Link></li>
                <li><Link to="/settings/system">System</Link></li>
                <li><Link to="/settings/about">About</Link></li>
            </ul>
        </div>
        </>
);
};

export default Screensaver;