import React, { useState, useEffect } from 'react';
import { 
  User, Mail, Phone, Shield, 
  Award, BookOpen, Save, Camera,
  ChevronRight, ArrowRight
} from 'lucide-react';
import api from '../../services/api';
import Avatar from '../../components/ui/Avatar';
import Button from '../../components/ui/Button';
import LoadingSpinner from '../../components/ui/LoadingSpinner';
import { toast } from 'react-hot-toast';

export default function TrainerProfile() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [profile, setProfile] = useState({
    name: '',
    email: '',
    phone: '',
    specialization: '',
    bio: '',
    experience: '',
    role: 'trainer'
  });

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const res = await api.get('/users/profile');
      if (res.data.success) {
        setProfile({
          ...profile,
          ...res.data.user
        });
      }
    } catch (err) {
      console.error('Failed to fetch trainer profile:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdate = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const res = await api.patch('/trainer/profile', {
        name: profile.name,
        phone: profile.phone,
        specialization: profile.specialization,
        bio: profile.bio,
        experience: profile.experience
      });
      if (res.data.success) {
        toast.success('Profile updated successfully!');
      }
    } catch (err) {
      toast.error('Failed to update profile');
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="max-w-4xl mx-auto space-y-8 animate-fade-in pb-20">
      {/* Profile Header Card */}
      <div className="bg-white rounded-[2.5rem] p-8 shadow-sm border border-gray-50 relative overflow-hidden group">
         <div className="relative z-10 flex flex-col md:flex-row items-center gap-8 text-center md:text-left">
            <div className="relative group/avatar">
               <Avatar name={profile.name} size="xl" />
               <button className="absolute bottom-0 right-0 bg-[#E8845C] text-white p-2 rounded-xl shadow-lg hover:scale-110 active:scale-95 transition-all">
                  <Camera size={16} />
               </button>
            </div>
            <div className="flex-1">
               <h1 className="text-3xl font-black text-gray-900 mb-1">{profile.name}</h1>
               <p className="text-[#E8845C] font-bold text-sm tracking-widest uppercase mb-3 px-1">{profile.specialization || 'Professional Trainer'}</p>
               <div className="flex flex-wrap items-center justify-center md:justify-start gap-4">
                  <div className="bg-gray-50 px-4 py-2 rounded-2xl flex items-center gap-2 border border-gray-100">
                     <Mail size={14} className="text-gray-400" />
                     <span className="text-xs font-bold text-gray-600 italic">{profile.email}</span>
                  </div>
                  <div className="bg-gray-50 px-4 py-2 rounded-2xl flex items-center gap-2 border border-gray-100">
                     <Shield size={14} className="text-gray-400" />
                     <span className="text-xs font-black text-gray-600 uppercase tracking-widest">Verified Trainer</span>
                  </div>
               </div>
            </div>
         </div>
         {/* Decorative blob */}
         <div className="absolute top-0 right-0 w-64 h-64 bg-orange-500/5 rounded-full blur-3xl -mr-32 -mt-32"></div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-5 gap-8">
         {/* Edit Form */}
         <form onSubmit={handleUpdate} className="md:col-span-3 space-y-6 bg-white p-8 rounded-[2.5rem] shadow-sm border border-gray-50">
            <h2 className="text-xl font-black text-gray-900 px-1 border-l-4 border-orange-500 pl-4 mb-4">Account Settings</h2>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
               <div className="space-y-2">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-1">Full Name</label>
                  <input 
                    type="text"
                    className="w-full bg-gray-50 border border-gray-100 rounded-2xl px-4 py-3 focus:outline-none focus:ring-4 focus:ring-[#E8845C]/5 focus:border-[#E8845C] transition-all font-bold text-sm"
                    value={profile.name}
                    onChange={(e) => setProfile({...profile, name: e.target.value})}
                  />
               </div>
               <div className="space-y-2">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-1">Phone Number</label>
                  <input 
                    type="tel"
                    className="w-full bg-gray-50 border border-gray-100 rounded-2xl px-4 py-3 focus:outline-none focus:ring-4 focus:ring-[#E8845C]/5 focus:border-[#E8845C] transition-all font-bold text-sm"
                    value={profile.phone}
                    onChange={(e) => setProfile({...profile, phone: e.target.value})}
                  />
               </div>
            </div>

            <div className="space-y-2">
               <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-1">Specialization</label>
               <input 
                 type="text"
                 placeholder="e.g. Strength Training, HIIT, Yoga"
                 className="w-full bg-gray-50 border border-gray-100 rounded-2xl px-4 py-3 focus:outline-none focus:ring-4 focus:ring-[#E8845C]/5 focus:border-[#E8845C] transition-all font-bold text-sm"
                 value={profile.specialization}
                 onChange={(e) => setProfile({...profile, specialization: e.target.value})}
               />
            </div>

            <div className="space-y-2">
               <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-1">About / Bio</label>
               <textarea 
                 rows="4"
                 placeholder="Share your philosophy and approach to training..."
                 className="w-full bg-gray-50 border border-gray-100 rounded-2xl px-4 py-3 focus:outline-none focus:ring-4 focus:ring-[#E8845C]/5 focus:border-[#E8845C] transition-all font-bold text-sm resize-none"
                 value={profile.bio}
                 onChange={(e) => setProfile({...profile, bio: e.target.value})}
               />
            </div>

            <div className="space-y-2">
               <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-1">Experience (Years)</label>
               <input 
                 type="text"
                 placeholder="e.g. 5+ years"
                 className="w-full bg-gray-50 border border-gray-100 rounded-2xl px-4 py-3 focus:outline-none focus:ring-4 focus:ring-[#E8845C]/5 focus:border-[#E8845C] transition-all font-bold text-sm"
                 value={profile.experience}
                 onChange={(e) => setProfile({...profile, experience: e.target.value})}
               />
            </div>

            <div className="pt-4">
               <Button 
                type="submit" 
                variant="primary" 
                className="w-full py-4 rounded-2xl shadow-lg shadow-orange-500/20 font-black tracking-widest gap-2"
                disabled={saving}
               >
                  {saving ? 'Updating...' : <><Save size={18} /> Update Profile</>}
               </Button>
            </div>
         </form>

         {/* Stats and Help Sidebar */}
         <div className="md:col-span-2 space-y-6">
            <div className="bg-[#0F1923] p-8 rounded-[2.5rem] text-white shadow-xl relative overflow-hidden group">
               <h3 className="text-lg font-black mb-6 flex items-center gap-2 relative z-10">
                  <Award size={22} className="text-[#E8845C]" />
                  Performance
               </h3>
               <div className="space-y-6 relative z-10">
                  <div>
                     <p className="text-[9px] text-[#64748B] uppercase font-black tracking-widest mb-1">Total Impact</p>
                     <p className="text-3xl font-black">542 <span className="text-xs font-bold text-gray-500">Sessions</span></p>
                  </div>
                  <div>
                     <p className="text-[9px] text-[#64748B] uppercase font-black tracking-widest mb-1">Client Retention</p>
                     <div className="flex items-center gap-3">
                        <div className="flex-1 bg-white/5 h-2 rounded-full overflow-hidden">
                           <div className="bg-[#E8845C] h-full w-[88%] rounded-full"></div>
                        </div>
                        <span className="text-sm font-black">88%</span>
                     </div>
                  </div>
                  <div>
                    <p className="text-[9px] text-[#64748B] uppercase font-black tracking-widest mb-1">Top Rating</p>
                    <div className="flex text-orange-400 gap-1">
                       {[1,2,3,4,5].map(i => <span key={i}>★</span>)}
                    </div>
                  </div>
               </div>
               <div className="absolute bottom-0 right-0 p-4 opacity-5 pointer-events-none group-hover:scale-110 transition-transform">
                  <Award size={120} />
               </div>
            </div>

            <div className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-gray-50">
               <h3 className="font-black text-gray-900 mb-6 flex items-center gap-2">
                  <BookOpen size={20} className="text-[#E8845C]" />
                  Resources
               </h3>
               <div className="space-y-3">
                  {['Trainer Guidelines', 'Safety Protocols', 'Community Forum'].map((item, i) => (
                    <button key={i} className="w-full flex items-center justify-between p-4 rounded-2xl hover:bg-gray-50 transition-all border border-transparent hover:border-gray-100 group">
                       <span className="text-sm font-bold text-gray-600 group-hover:text-[#E8845C] transition-colors">{item}</span>
                       <ChevronRight size={16} className="text-gray-300 group-hover:translate-x-1 transition-transform" />
                    </button>
                  ))}
               </div>
            </div>

            <div className="bg-gradient-to-br from-[#E8845C] to-[#D4673A] p-8 rounded-[2.5rem] text-white shadow-xl shadow-orange-500/20 group cursor-pointer">
               <div className="flex justify-between items-start mb-4">
                  <div className="w-12 h-12 rounded-2xl bg-white/20 flex items-center justify-center">
                     <Shield size={24} />
                  </div>
                  <ArrowRight size={20} className="group-hover:translate-x-2 transition-transform" />
               </div>
               <h4 className="text-lg font-black leading-tight">Apply for Certification</h4>
               <p className="text-xs font-medium text-white/70 mt-1">Upgrade your profile with verified fitness certificates.</p>
            </div>
         </div>
      </div>
    </div>
  );
}
