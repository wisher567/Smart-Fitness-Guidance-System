import { useState } from 'react';
import { Save, Building2, Bell, Shield, Wallet } from 'lucide-react';
import { toast } from 'react-hot-toast';

export default function Settings() {
  const [activeTab, setActiveTab] = useState('gym');
  
  // Gym Profile State
  const [gymData, setGymData] = useState({
    name: 'FitFusion Elite',
    email: 'admin@fitfusion.com',
    phone: '+94 77 123 4567',
    address: '123 Fitness Lane, Colombo 03',
    currency: 'LKR',
    taxRate: 15
  });

  const handleSave = (e) => {
    e.preventDefault();
    toast.success('Settings saved successfully');
  };

  return (
    <div className="space-y-6 animate-fade-in-up max-w-5xl mx-auto">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Settings</h2>
        <p className="text-gray-500 text-sm mt-1">Manage your gym preferences and account settings</p>
      </div>

      <div className="flex flex-col md:flex-row gap-8">
        
        {/* Settings Navigation */}
        <div className="w-full md:w-64 shrink-0">
          <nav className="flex md:flex-col gap-2 overflow-x-auto pb-2 md:pb-0">
            <button onClick={() => setActiveTab('gym')} className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors text-left whitespace-nowrap ${activeTab === 'gym' ? 'bg-primary text-white shadow-md' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}`}>
              <Building2 size={18} /> Gym Profile
            </button>
             <button onClick={() => setActiveTab('billing')} className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors text-left whitespace-nowrap ${activeTab === 'billing' ? 'bg-primary text-white shadow-md' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}`}>
              <Wallet size={18} /> Billing & Tax
            </button>
            <button onClick={() => setActiveTab('notifications')} className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors text-left whitespace-nowrap ${activeTab === 'notifications' ? 'bg-primary text-white shadow-md' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}`}>
              <Bell size={18} /> Notifications
            </button>
            <button onClick={() => setActiveTab('security')} className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors text-left whitespace-nowrap ${activeTab === 'security' ? 'bg-primary text-white shadow-md' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}`}>
              <Shield size={18} /> Security
            </button>
          </nav>
        </div>

        {/* Settings Content */}
        <div className="flex-1 bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8">
          
          {activeTab === 'gym' && (
            <form onSubmit={handleSave} className="space-y-6">
              <h3 className="text-lg font-bold text-gray-900 mb-4 border-b border-gray-100 pb-2">Gym Information</h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-1">Gym Name</label>
                  <input type="text" value={gymData.name} onChange={e => setGymData({...gymData, name: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Contact Email</label>
                  <input type="email" value={gymData.email} onChange={e => setGymData({...gymData, email: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                  <input type="text" value={gymData.phone} onChange={e => setGymData({...gymData, phone: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
                </div>

                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
                  <textarea rows="3" value={gymData.address} onChange={e => setGymData({...gymData, address: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
                </div>
              </div>

              <div className="pt-6 border-t border-gray-100 flex justify-end">
                <button type="submit" className="flex items-center gap-2 bg-primary hover:bg-primaryDark text-white font-semibold px-6 py-2.5 rounded-xl transition-colors">
                  <Save size={18} /> Save Changes
                </button>
              </div>
            </form>
          )}

          {activeTab === 'billing' && (
            <form onSubmit={handleSave} className="space-y-6">
              <h3 className="text-lg font-bold text-gray-900 mb-4 border-b border-gray-100 pb-2">Billing & Tax Preferences</h3>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Default Currency</label>
                  <select value={gymData.currency} onChange={e => setGymData({...gymData, currency: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20">
                    <option value="LKR">LKR (Sri Lankan Rupee)</option>
                    <option value="USD">USD (US Dollar)</option>
                  </select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Tax Rate (%)</label>
                  <input type="number" value={gymData.taxRate} onChange={e => setGymData({...gymData, taxRate: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
                </div>
              </div>
              
              <div className="pt-6 border-t border-gray-100 flex justify-end">
                <button type="submit" className="flex items-center gap-2 bg-primary hover:bg-primaryDark text-white font-semibold px-6 py-2.5 rounded-xl transition-colors">
                  <Save size={18} /> Save Preferences
                </button>
              </div>
            </form>
          )}

          {activeTab === 'notifications' && (
            <div className="space-y-6">
              <h3 className="text-lg font-bold text-gray-900 mb-4 border-b border-gray-100 pb-2">Notification Preferences</h3>
              
              <div className="space-y-4">
                {[
                  { id: 'new_member', label: 'New Member Signups', desc: 'Get notified when a new member joins the gym.' },
                  { id: 'payment_failed', label: 'Failed Payments', desc: 'Get notified when a member subscription payment fails.' },
                  { id: 'equip_alert', label: 'Equipment Alerts', desc: 'Get notified when a new equipment issue is reported.' },
                  { id: 'daily_summary', label: 'Daily Summary Email', desc: 'Receive a daily email summarizing gym activity and revenue.' },
                ].map((item, i) => (
                  <div key={item.id} className="flex items-start justify-between py-3 border-b border-gray-50 last:border-0 hover:bg-gray-50 px-2 rounded-lg transition-colors">
                    <div>
                      <p className="font-semibold text-gray-900">{item.label}</p>
                      <p className="text-sm text-gray-500">{item.desc}</p>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer mt-1">
                      <input type="checkbox" className="sr-only peer" defaultChecked={i !== 3} />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    </label>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeTab === 'security' && (
            <div className="space-y-6">
              <h3 className="text-lg font-bold text-gray-900 mb-4 border-b border-gray-100 pb-2">Account Security</h3>
              
              <div className="space-y-4 max-w-md">
                <p className="text-sm text-gray-600 mb-4">To change your admin password, you must use the Firebase password reset function or update it here if enabled.</p>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Current Password</label>
                  <input type="password" placeholder="••••••••" className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">New Password</label>
                  <input type="password" placeholder="••••••••" className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Confirm New Password</label>
                  <input type="password" placeholder="••••••••" className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
                </div>
                
                <div className="pt-2">
                  <button onClick={(e) => {e.preventDefault(); toast.success('Password update link sent to your email.'); }} className="w-full bg-dark hover:bg-gray-800 text-white font-semibold px-4 py-2 rounded-xl transition-colors">
                    Update Password
                  </button>
                </div>
              </div>
            </div>
          )}

        </div>
      </div>
    </div>
  );
}
