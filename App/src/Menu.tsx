import React from 'react';

const Screensaver: React.FC = () => {
    return (
        <div>
            <h1>Settings Menu</h1>
            <ul>
                <li><button onClick={() => window.location.href = '/settings/display'}>Display</button></li>
                <li><button onClick={() => window.location.href = '/settings/sound'}>Sound</button></li>
                <li><button onClick={() => window.location.href = '/settings/network'}>Network</button></li>
                <li><button onClick={() => window.location.href = '/settings/system'}>System</button></li>
                <li><button onClick={() => window.location.href = '/settings/about'}>About</button></li>
            </ul>
        </div>
    );
};


export default Screensaver;