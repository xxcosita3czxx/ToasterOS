import { useState } from 'react'
import { Link } from 'react-router-dom';

function Sound() {
  const isXScreenSaverWindow = typeof process !== 'undefined' && process.env.XSCREENSAVER_WINDOW !== undefined;

  return (
    <div className='App'>
        <p>Sound</p>
        <li><Link to="/">Back</Link></li>
    </div>
  )
}

export default Sound