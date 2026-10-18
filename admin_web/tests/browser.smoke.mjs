// Optional: requires an existing Playwright installation and Chromium.
// Fixtures are isolated to this test server. External Firebase calls are blocked.
import assert from 'node:assert/strict'
import { createServer } from 'vite'
import { chromium } from 'playwright'
const fixtures = {
 special_requests: [],
 schedules: [{ _docId:'S-1',scheduleId:'S-1',zone:'Test zone',collectionDate:'2026-10-11',startTime:'08:00',endTime:'10:00',wasteType:'general',status:'scheduled',assignedDriverId:'D-1',assignedVehicleId:'V-1' }],
 drivers: [{ _docId:'D-1',driverId:'D-1',fullName:'Fixture Driver',email:'fixture@example.invalid',phoneNumber:'000',licenseNumber:'TEST',status:'available' }],
 vehicles: [{ _docId:'V-1',registrationNumber:'V-1',vehicleType:'Fixture Truck',capacityKg:0,status:'available' }],
 staff: [{ _docId:'T-1',staffId:'T-1',fullName:'Fixture Staff',email:'fixture@example.invalid',phoneNumber:'000',position:'Collector',status:'active' }],
 missedCollectionReports: [{_docId:'M-1',scheduleId:'S-1',collectionDate:'2026-10-11',wasteType:'recyclable',reason:'Collection missed',description:'Fixture report details',reportStatus:'pending'}],
}
const backend = `import {normalizeRecord} from '/src/services/domain.js';
let records=${JSON.stringify(fixtures)}, listeners={};
export const LIST_LIMIT=500;
export function subscribeCollection(name,data,error){(listeners[name] ||= new Set()).add(data);queueMicrotask(()=>data([...records[name]],{cached:false,pending:false}));return ()=>listeners[name].delete(data)}
export const subscribeVehicles=(a,b)=>subscribeCollection('vehicles',a,b),subscribeDrivers=(a,b)=>subscribeCollection('drivers',a,b),subscribeStaff=(a,b)=>subscribeCollection('staff',a,b),subscribeSchedules=(a,b)=>subscribeCollection('schedules',a,b);
export const collectionCount=async name=>records[name].length;
function notify(kind){for(const callback of listeners[kind]||[])callback([...records[kind]],{cached:false,pending:false})}
export async function saveRecord(kind,input,originalId){await new Promise(resolve=>setTimeout(resolve,80));if(input.scheduleId==='FAIL')throw new Error('Fixture write denied');const data=normalizeRecord(kind,input),id=originalId||data.scheduleId||data.driverId||data.staffId||data.registrationNumber,index=records[kind].findIndex(row=>row._docId===id);if(!originalId&&index>=0)throw new Error('ID already exists');if(originalId)records[kind][index]={...records[kind][index],...data};else records[kind].push({...data,_docId:id});notify(kind)}
export async function deleteRecord(kind,id){records[kind]=records[kind].filter(row=>row._docId!==id);notify(kind)}
`
const plugin = {name:'test-only-fixtures',enforce:'pre',resolveId(id,importer){
 if(id==='firebase/auth'&&importer?.endsWith('/Sidebar.jsx'))return '\0test-auth';
 if(id==='firebase/firestore'&&importer?.endsWith('/UserManagementPage.jsx'))return '\0test-profile';
},load(id){
 if(id==='\0test-auth')return 'export const signOut=async()=>{}';
 if(id==='\0test-profile')return "export const doc=(db,collection,uid)=>{if(collection!=='users'||uid!=='fixture-only')throw new Error('Account view must read only its own profile');return {}};let attempts=0;export const onSnapshot=(ref,options,callback,error)=>{let active=true;const state=new URLSearchParams(location.search).get('profile');queueMicrotask(()=>{if(!active)return;if(state==='loading')return;if(state==='error'&&attempts++===0){error({code:'permission-denied',message:'private detail'});return}callback({exists:()=>state!=='missing',data:()=>({role:'officer'}),metadata:{fromCache:false,hasPendingWrites:false}})});return ()=>{active=false}}";
 if(id.endsWith('/src/services/firestoreService.js'))return backend;
 if(id.endsWith('/src/services/firebase.js'))return "export const auth={currentUser:{uid:'fixture-only',email:'officer@example.invalid'}},db={};export const ensureOfficer=async()=>auth.currentUser";
 if(id.endsWith('/src/main.jsx'))return "import React from 'react';import {createRoot} from 'react-dom/client';import {BrowserRouter} from 'react-router-dom';import App from './App.jsx';import './index.css';createRoot(document.getElementById('root')).render(<BrowserRouter><App/></BrowserRouter>)";
}}
let server,browser
try{
 browser=await chromium.launch({headless:true});
 const context=await browser.newContext({viewport:{width:1440,height:1000}});
 await context.route('**/*',route=>new URL(route.request().url()).hostname==='127.0.0.1'?route.continue():route.abort());
 let page=await context.newPage();const errors=[];page.on('pageerror',error=>errors.push(error.message));
 server=await createServer({server:{host:'127.0.0.1',port:5176,strictPort:true}});await server.listen();
 await page.goto('http://127.0.0.1:5176');await page.getByRole('button',{name:'Sign in',exact:true}).waitFor();
 assert.equal(await page.getByLabel('Password').getAttribute('type'),'password');await page.close();await server.close();
 server=await createServer({plugins:[plugin],server:{host:'127.0.0.1',port:5176,strictPort:true}});await server.listen();page=await context.newPage();page.on('pageerror',error=>errors.push(error.message));
 for(const [path,title] of [['dashboard','Dashboard'],['users','User Management'],['vehicles','Vehicle Management'],['staff','Staff Management'],['drivers','Driver Management'],['schedule','Collection Schedule'],['live-tracking','Live Collection Tracking'],['special-requests','Special Waste Collection'],['notifications','Notification Management'],['complaints','Complaints & Feedback'],['reports','Reports & Analytics']]){
  await page.goto('http://127.0.0.1:5176/'+path);await page.getByRole('heading',{level:1,name:title,exact:true}).waitFor();assert.equal(await page.getByText('Coming soon',{exact:false}).count(),0);
 }
 await page.goto('http://127.0.0.1:5176/routes');await page.getByRole('heading',{level:1,name:'Dashboard',exact:true}).waitFor();assert.equal(new URL(page.url()).pathname,'/dashboard');assert.equal(await page.getByRole('link',{name:'Route Management',exact:true}).count(),0);
 await page.goto('http://127.0.0.1:5176/notifications');await page.getByRole('status').getByText('Notification history is not available yet',{exact:true}).waitFor();assert.equal(await page.getByText('Backend prerequisite',{exact:true}).count(),0);
 await page.screenshot({path:'/tmp/cleancycle-notifications-desktop.png',fullPage:true});await page.setViewportSize({width:390,height:844});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth),false);await page.screenshot({path:'/tmp/cleancycle-notifications-mobile.png',fullPage:true});await page.setViewportSize({width:1440,height:1000});
 await page.goto('http://127.0.0.1:5176/complaints');
 assert.equal(await page.getByText('Backend prerequisite',{exact:true}).count(),0);
 await page.getByRole('button',{name:'View report',exact:true}).click();await page.getByRole('dialog').getByText('Fixture report details',{exact:true}).waitFor();await page.getByRole('button',{name:'Close dialog',exact:true}).click();
 await page.getByLabel('Search reports',{exact:true}).fill('missing search');await page.getByText('No reports match your search or status filter.',{exact:true}).waitFor();await page.getByLabel('Search reports',{exact:true}).fill('S-1');await page.getByLabel('Report status',{exact:true}).selectOption('pending');assert.equal(await page.getByRole('button',{name:'View report',exact:true}).count(),1);
 await page.getByRole('button',{name:'Refresh reports',exact:true}).click();await page.getByRole('button',{name:'View report',exact:true}).waitFor();
 await page.screenshot({path:'/tmp/cleancycle-complaints-desktop.png',fullPage:true});await page.setViewportSize({width:390,height:844});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth),false);await page.screenshot({path:'/tmp/cleancycle-complaints-mobile.png',fullPage:true});await page.setViewportSize({width:1440,height:1000});
 await page.goto('http://127.0.0.1:5176/users?profile=loading');await page.getByText('Loading your profile…',{exact:true}).waitFor();
 await page.goto('http://127.0.0.1:5176/users?profile=missing');await page.getByRole('status').filter({hasText:'No profile is recorded'}).waitFor();
 await page.goto('http://127.0.0.1:5176/users?profile=error');await page.getByRole('alert').filter({hasText:'current account permissions'}).waitFor();await page.getByRole('button',{name:'Retry profile'}).click();await page.locator('dd').filter({hasText:'Municipal Officer'}).waitFor();assert.equal(await page.getByRole('alert').count(),0);
 await page.screenshot({path:'/tmp/cleancycle-users-desktop.png',fullPage:true});
 await page.setViewportSize({width:390,height:844});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth),false);await page.screenshot({path:'/tmp/cleancycle-users-mobile.png',fullPage:true});await page.setViewportSize({width:1440,height:1000});
 await page.goto('http://127.0.0.1:5176/schedule');
 await page.getByRole('button',{name:'+ Add Schedule',exact:true}).click();
 async function fillSchedule(id,end){await page.getByLabel('Schedule ID *').fill(id);await page.getByLabel('Zone *',{exact:true}).fill('Fixture zone');await page.getByLabel('Collection Date *').fill('2026-10-12');await page.getByLabel('Start Time *').fill('08:00');await page.getByLabel('End Time *').fill(end)}
 await fillSchedule('S-2','07:00');await page.getByRole('button',{name:'Save Schedule',exact:true}).click();await page.getByRole('alert').filter({hasText:'End time must be after start time'}).waitFor();
 await page.getByLabel('End Time *').fill('09:00');await page.getByRole('button',{name:'Save Schedule',exact:true}).click();await page.getByText('Schedule created successfully.',{exact:true}).waitFor();
 const row=page.getByRole('row').filter({hasText:'S-2'});
 await row.getByRole('button',{name:'View',exact:true}).click();await page.getByRole('dialog').waitFor();await page.getByRole('button',{name:'Close dialog',exact:true}).click();
 await row.getByRole('button',{name:'Edit',exact:true}).click();assert.equal(await page.getByLabel('Schedule ID *').getAttribute('readonly'),'');await page.getByLabel('Zone *',{exact:true}).fill('Edited fixture');await page.getByRole('button',{name:'Save Schedule',exact:true}).click();await page.getByText('Schedule updated successfully.',{exact:true}).waitFor();
 await row.getByRole('button',{name:'Delete',exact:true}).click();await page.getByRole('button',{name:'Cancel',exact:true}).click();assert.equal(await row.count(),1);
 await row.getByRole('button',{name:'Delete',exact:true}).click();await page.getByRole('button',{name:'Confirm deletion',exact:true}).click();await page.getByText('Schedule deleted successfully.',{exact:true}).waitFor();
 await page.getByRole('button',{name:'+ Add Schedule',exact:true}).click();await fillSchedule('FAIL','09:00');await page.getByRole('button',{name:'Save Schedule',exact:true}).click();await page.getByRole('alert').filter({hasText:'Fixture write denied'}).waitFor();assert.equal(await page.getByRole('dialog').count(),1);assert.equal(await page.getByText('Schedule created successfully.',{exact:true}).count(),0);await page.getByRole('button',{name:'Cancel',exact:true}).click();
 await page.goto('http://127.0.0.1:5176/reports');await page.getByLabel('From',{exact:true}).fill('2026-10-12');await page.getByLabel('To',{exact:true}).fill('2026-10-12');assert.ok(await page.getByRole('button',{name:'Export schedules CSV'}).isDisabled());await page.getByLabel('From',{exact:true}).fill('2026-10-11');await page.getByLabel('To',{exact:true}).fill('2026-10-11');const downloadPromise=page.waitForEvent('download');await page.getByRole('button',{name:'Export schedules CSV'}).click();assert.ok((await downloadPromise).suggestedFilename().endsWith('.csv'));
 await page.setViewportSize({width:768,height:1024});await page.goto('http://127.0.0.1:5176/schedule');await page.getByRole('button',{name:'Toggle navigation'}).click();assert.ok(await page.getByRole('navigation',{name:'Sidebar navigation'}).isVisible());await page.getByRole('navigation',{name:'Sidebar navigation'}).getByRole('link',{name:'Reports',exact:true}).click();await page.getByRole('heading',{name:'Reports & Analytics',exact:true}).waitFor();assert.equal(await page.getByRole('navigation',{name:'Sidebar navigation'}).isVisible(),false);assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth),false);await page.screenshot({path:'/tmp/cleancycle-reports-tablet.png',fullPage:true});
 await page.setViewportSize({width:1440,height:1000});await page.goto('http://127.0.0.1:5176/schedule');await page.screenshot({path:'/tmp/cleancycle-schedule-desktop.png',fullPage:true});assert.deepEqual(errors,[]);
 console.log('Passed: User Management own-profile source, loading, missing, error/retry and mobile layout; real sign-in screen; 11 portal pages with test fixtures; schedule CRUD, validation and failed save; details; date filters; CSV; tablet navigation. No production Firebase calls.');
}finally{await browser?.close();await server?.close()}
