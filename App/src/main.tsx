import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';
import { BrowserRouter, Routes, Route } from 'react-router-dom';

import Face from './settings/Face';
import Sound from './settings/Sound';
import System from './settings/System';
import About from './settings/About';


ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
      <Routes>
        <Route path="/" element={<App />} />
        <Route path="/settings/face" element={<Face />} />
        <Route path="/settings/sound" element={<Sound />} />
        <Route path="/settings/system" element={<System />} />
        <Route path="/settings/about" element={<About />} />
      </Routes>
    </BrowserRouter>
  </React.StrictMode>
);

postMessage({ payload: 'removeLoading' }, '*');
