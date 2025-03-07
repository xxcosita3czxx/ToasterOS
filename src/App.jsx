import * as React from 'react';
import { createRoot } from 'react-dom/client';
import { render } from 'react-dom';
import './index.css';
const root = createRoot(document.body);
root.render(
    <>
    <div className='main'>
        <h1>My First React App</h1>
        <p>This is a simple React app.</p>
    </div>
    </>
);