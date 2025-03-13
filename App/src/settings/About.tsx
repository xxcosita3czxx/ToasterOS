import { useState } from 'react'
import { Link } from 'react-router-dom';

function About() {
  const isXScreenSaverWindow = typeof process !== 'undefined' && process.env.XSCREENSAVER_WINDOW !== undefined;

  return (
    <div className='App'>
        <p>about</p>
        <li><Link to="/">Back</Link></li>
    </div>
  )
}

export default About