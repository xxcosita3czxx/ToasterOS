import React, { useState } from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import Navbar from './components/Navbar';
import "./Menu.css";

const Menu: React.FC = () => {
    const [sidebarOpen, setSidebarOpen] = useState(false);

    const toggleSidebar = () => {
        setSidebarOpen(!sidebarOpen);
    };

    return (
        <>
            <Navbar toggleSidebar={toggleSidebar} />
            <div className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
                {/* Sidebar content can be added here if needed */}
            </div>
            <div className="content">
                <Routes>
                    <Route path="/settings/face" element={<div>Face Settings</div>} />
                    <Route path="/settings/system" element={<div>System Settings</div>} />
                    <Route path="/settings/sound" element={<div>Sound Settings</div>} />
                    <Route path="/settings/about" element={<div>About</div>} />
                </Routes>
            </div>
        </>
    );
};

export default Menu;