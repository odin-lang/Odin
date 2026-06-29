// Bindings for [[ PortMidi ; http://sourceforge.net/projects/portmedia ]] Portable Real-Time MIDI Library.
package portmidi

/*
 * PortMidi Portable Real-Time MIDI Library
 * PortMidi API Header File
 * Latest version available at: http://sourceforge.net/projects/portmedia
 *
 * Copyright (c) 1999-2000 Ross Bencina and Phil Burk
 * Copyright (c) 2001-2006 Roger B. Dannenberg
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 * The text above constitutes the entire PortMidi license; however, 
 * the PortMusic community also makes the following non-binding requests:
 *
 * Any person wishing to distribute modifications to the Software is
 * requested to send the modifications to the original developer so that
 * they can be incorporated into the canonical version. It is also
 * requested that these non-binding requests be included along with the 
 * license above.
 */

/* CHANGELOG FOR PORTMIDI
 *     (see ../CHANGELOG.txt)
 *
 * NOTES ON HOST ERROR REPORTING: 
 *
 *    PortMidi errors (of type PmError) are generic, system-independent errors.
 *    When an error does not map to one of the more specific PmErrors, the
 *    catch-all code pmHostError is returned. This means that PortMidi has
 *    retained a more specific system-dependent error code. The caller can
 *    get more information by calling Pm_HasHostError() to test if there is
 *    a pending host error, and Pm_GetHostErrorText() to get a text string
 *    describing the error. Host errors are reported on a per-device basis 
 *    because only after you open a device does PortMidi have a place to 
 *    record the host error code. I.e. only 
 *    those routines that receive a (PortMidiStream *) argument check and 
 *    report errors. One exception to this is that Pm_OpenInput() and 
 *    Pm_OpenOutput() can report errors even though when an error occurs,
 *    there is no PortMidiStream* to hold the error. Fortunately, both
 *    of these functions return any error immediately, so we do not really
 *    need per-device error memory. Instead, any host error code is stored
 *    in a global, pmHostError is returned, and the user can call 
 *    Pm_GetHostErrorText() to get the error message (and the invalid stream
 *    parameter will be ignored.) The functions 
 *    pm_init and pm_term do not fail or raise
 *    errors. The job of pm_init is to locate all available devices so that
 *    the caller can get information via PmDeviceInfo(). If an error occurs,
 *    the device is simply not listed as available.
 *
 *    Host errors come in two flavors:
 *      a) host error 
 *      b) host error during callback
 *    These can occur w/midi input or output devices. (b) can only happen 
 *    asynchronously (during callback routines), whereas (a) only occurs while
 *    synchronously running PortMidi and any resulting system dependent calls.
 *    Both (a) and (b) are reported by the next read or write call. You can
 *    also query for asynchronous errors (b) at any time by calling
 *    Pm_HasHostError().
 *
 * NOTES ON COMPILE-TIME SWITCHES
 *
 *    DEBUG assumes stdio and a console. Use this if you want automatic, simple
 *        error reporting, e.g. for prototyping. If you are using MFC or some 
 *        other graphical interface with no console, DEBUG probably should be
 *        undefined.
 *    PM_CHECK_ERRORS more-or-less takes over error checking for return values,
 *        stopping your program and printing error messages when an error
 *        occurs. This also uses stdio for console text I/O.
 */