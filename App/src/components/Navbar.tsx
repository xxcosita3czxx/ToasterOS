import React from 'react';
import { Link } from 'react-router-dom';

interface NavbarProps {
    toggleSidebar: () => void;
}

const Navbar: React.FC<NavbarProps> = ({ toggleSidebar }) => {
    return (
        <div className="navbar">
            <button className="burger-menu" onClick={toggleSidebar}>
                &#9776;
            </button>
            <div className="navbar-title">Settings</div>
            <div className="navbar-links">
                <Link to="/settings/face" className="navbar-item">Face</Link>
                <Link to="/settings/system" className="navbar-item">System</Link>
                <Link to="/settings/sound" className="navbar-item">Sound</Link>
                <Link to="/settings/about" className="navbar-item">About</Link>
            </div>
        </div>
    );
};

export default Navbar;