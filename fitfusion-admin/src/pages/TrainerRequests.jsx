import { useState, useEffect } from 'react';
import { UserCheck, CheckCircle, XCircle, RefreshCw } from 'lucide-react';
import api from '../services/api';
import { toast } from 'react-hot-toast';

export default function TrainerRequests() {
  const [requests, setRequests] = useState([]);
  const [stats, setStats] = useState({});
  const [activeTab, setActiveTab] = useState('pending');
  const [isLoading, setIsLoading] = useState(true);
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [adminNote, setAdminNote] = useState('');
  const [isUpdating, setIsUpdating] = useState(false);

  const [sessionDate, setSessionDate]         = useState('');
  const [sessionTime, setSessionTime]         = useState('');
  const [sessionLocation, setSessionLocation] = useState('Main Gym Floor');
  const [sessionDuration, setSessionDuration] = useState('60 minutes');
  const [sessionNotes, setSessionNotes]       = useState('');

  useEffect(() => { fetchRequests(); }, []);

  const fetchRequests = async () => {
    try {
      const res = await api.get('/admin/trainer-requests');
      setRequests(res.data.requests || []);
      setStats(res.data.stats || {});
    } catch { toast.error('Failed to load requests'); }
    finally { setIsLoading(false); }
  };

  const handleAction = async (id, status) => {
    setIsUpdating(true);
    try {
      await api.patch(`/admin/trainer-requests/${id}`, {
        status,
        adminNote,
        sessionDate,
        sessionTime,
        sessionLocation,
        sessionNotes,
        sessionDuration,
      });
      toast.success(
        status === 'approved'
          ? '✅ Approved! Emails sent to trainer and member with session details.'
          : '❌ Rejected. Member notified by email.'
      );
      setSelectedRequest(null);
      resetForm();
      fetchRequests();
    } catch {
      toast.error('Failed to update request');
    } finally {
      setIsUpdating(false);
    }
  };

  const resetForm = () => {
    setAdminNote('');
    setSessionDate('');
    setSessionTime('');
    setSessionLocation('Main Gym Floor');
    setSessionDuration('60 minutes');
    setSessionNotes('');
  };

  const filtered = requests.filter(r => activeTab === 'all' ? true : r.status === activeTab);

  const tabs = [
    { key: 'pending',  label: 'Pending',  count: stats.pending },
    { key: 'approved', label: 'Approved', count: stats.approved },
    { key: 'rejected', label: 'Rejected', count: stats.rejected },
    { key: 'all',      label: 'All',      count: stats.total },
  ];

  const getInitials = (name = '') => {
    const parts = name.trim().split(' ');
    return parts.length >= 2 ? `${parts[0][0]}${parts[1][0]}`.toUpperCase() : name[0]?.toUpperCase() || '?';
  };

  const formatDate = (d) => {
    if (!d) return '';
    return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  const statusColors = {
    pending:  'bg-amber-50 text-amber-700 border-amber-200',
    approved: 'bg-green-50 text-green-700 border-green-200',
    rejected: 'bg-red-50 text-red-600 border-red-200',
  };

  return (
    <div className="space-y-6 animate-fade-in-up">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            Trainer Requests
            {(stats.pending || 0) > 0 && (
              <span className="px-2 py-0.5 bg-amber-100 text-amber-600 text-sm font-bold rounded-xl">
                {stats.pending} pending
              </span>
            )}
          </h1>
          <p className="text-gray-500 text-sm mt-1">Member requests for personal trainer assistance</p>
        </div>
        <button onClick={fetchRequests}
          className="flex items-center gap-2 px-4 py-2.5 bg-white border border-gray-200 rounded-xl text-sm text-gray-600 hover:bg-gray-50 transition-all">
          <RefreshCw size={15} /> Refresh
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Total',    value: stats.total    || 0, color: 'bg-gray-50',   text: 'text-gray-600',  icon: '📋' },
          { label: 'Pending',  value: stats.pending  || 0, color: 'bg-amber-50',  text: 'text-amber-600', icon: '⏳' },
          { label: 'Approved', value: stats.approved || 0, color: 'bg-green-50',  text: 'text-green-600', icon: '✅' },
          { label: 'Rejected', value: stats.rejected || 0, color: 'bg-red-50',    text: 'text-red-600',   icon: '❌' },
        ].map(s => (
          <div key={s.label} className={`${s.color} rounded-2xl p-4 border border-white/50`}>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xl">{s.icon}</span>
              <span className={`text-2xl font-bold ${s.text}`}>{s.value}</span>
            </div>
            <p className={`text-sm font-medium ${s.text}`}>{s.label}</p>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-1 flex gap-1 w-fit">
        {tabs.map(tab => (
          <button key={tab.key} onClick={() => setActiveTab(tab.key)}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium transition-all
              ${activeTab === tab.key ? 'bg-[#E8845C] text-white shadow-sm' : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'}`}>
            {tab.label}
            {(tab.count || 0) > 0 && (
              <span className={`text-xs px-1.5 py-0.5 rounded-full font-bold
                ${activeTab === tab.key ? 'bg-white/20 text-white' : 'bg-gray-100 text-gray-500'}`}>
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Requests list */}
      {isLoading ? (
        <div className="space-y-3">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="bg-white rounded-2xl border border-gray-100 p-6 animate-pulse h-24" />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm flex flex-col items-center justify-center py-16">
          <UserCheck size={48} className="text-gray-200 mb-4" />
          <h3 className="text-gray-600 font-semibold">No requests here</h3>
          <p className="text-gray-400 text-sm mt-1">
            {activeTab === 'pending' ? 'No pending requests right now' : 'Nothing to show for this filter'}
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map(req => (
            <div key={req.id} className="bg-white rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-all p-5">
              <div className="flex items-start gap-4 flex-wrap">
                {/* Avatar */}
                <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#E8845C] to-[#D4673A] flex items-center justify-center text-white font-bold text-lg shrink-0">
                  {getInitials(req.memberName)}
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2 flex-wrap">
                    <div>
                      <h3 className="font-bold text-gray-900 text-base">{req.memberName}</h3>
                      <p className="text-gray-500 text-sm">{req.memberEmail}</p>
                    </div>
                    <span className={`text-xs font-semibold px-2.5 py-1 rounded-full border capitalize ${statusColors[req.status] || ''}`}>
                      {req.status}
                    </span>
                  </div>

                  <div className="flex flex-wrap gap-4 mt-2 text-sm text-gray-500">
                    <span>👨‍💼 Requesting: <strong className="text-gray-700">{req.trainerName}</strong></span>
                    <span>🕒 Requested on: {formatDate(req.createdAt)}</span>
                  </div>

                  {(req.preferredDate || req.preferredTime) && (
                    <div className="mt-2 text-sm text-[#E8845C] font-medium flex gap-3">
                      {req.preferredDate && <span>📅 Prefers: {req.preferredDate}</span>}
                      {req.preferredTime && <span>⏰ At: {req.preferredTime}</span>}
                    </div>
                  )}

                  {req.message && (
                    <div className="mt-3 p-3 bg-gray-50 rounded-xl text-sm text-gray-600 italic border border-gray-100">
                      "{req.message}"
                    </div>
                  )}

                  {req.adminNote && (
                    <div className="mt-2 p-3 bg-orange-50 rounded-xl text-sm text-orange-700 border border-orange-100">
                      <strong>Admin note:</strong> {req.adminNote}
                    </div>
                  )}

                  {/* Action buttons */}
                  {req.status === 'pending' && (
                    <div className="flex gap-2 mt-4">
                      <button onClick={() => { 
                        setSelectedRequest(req); 
                        setAdminNote(''); 
                        setSessionDate(req.preferredDate || '');
                        setSessionTime(req.preferredTime || '');
                      }}
                        className="flex items-center gap-1.5 px-4 py-2 bg-green-50 border border-green-100 text-green-700 rounded-xl text-sm font-semibold hover:bg-green-100 transition-colors">
                        <CheckCircle size={14} /> Approve
                      </button>
                      <button onClick={async () => {
                          if (confirm('Reject this request?')) await handleAction(req.id, 'rejected');
                        }}
                        className="flex items-center gap-1.5 px-4 py-2 bg-red-50 border border-red-100 text-red-600 rounded-xl text-sm font-semibold hover:bg-red-100 transition-colors">
                        <XCircle size={14} /> Reject
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Approve Modal */}
      {selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => { setSelectedRequest(null); resetForm(); }} />
          <div className="relative bg-white rounded-3xl shadow-xl w-full max-w-lg border border-gray-100 animate-slide-up my-4 flex flex-col max-h-[90vh]">
            <div className="p-6 border-b border-gray-100 shrink-0">
              <h3 className="font-bold text-gray-900 text-lg">Approve & Schedule First Session</h3>
              <p className="text-gray-500 text-sm mt-1">
                Assign <strong>{selectedRequest.memberName}</strong> to trainer <strong>{selectedRequest.trainerName}</strong>
              </p>
            </div>
            <div className="p-6 space-y-5 overflow-y-auto flex-1">
              {selectedRequest.message && (
                <div className="p-4 bg-gray-50 rounded-2xl border border-gray-100">
                  <p className="text-xs font-semibold text-gray-400 mb-1">MEMBER'S MESSAGE</p>
                  <p className="text-gray-700 text-sm italic">"{selectedRequest.message}"</p>
                </div>
              )}

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-sm font-semibold text-gray-700 block mb-1.5">📅 Session Date *</label>
                  <input type="date" value={sessionDate} onChange={e => setSessionDate(e.target.value)} min={new Date().toISOString().split('T')[0]}
                    className="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 focus:border-[#E8845C]" />
                </div>
                <div>
                  <label className="text-sm font-semibold text-gray-700 block mb-1.5">🕐 Session Time *</label>
                  <input type="time" value={sessionTime} onChange={e => setSessionTime(e.target.value)}
                    className="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 focus:border-[#E8845C]" />
                </div>
              </div>

              <div>
                <label className="text-sm font-semibold text-gray-700 block mb-1.5">📍 Location</label>
                <select value={sessionLocation} onChange={e => setSessionLocation(e.target.value)}
                  className="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 focus:border-[#E8845C] cursor-pointer">
                  <option>Main Gym Floor</option>
                  <option>Studio A</option>
                  <option>Studio B</option>
                  <option>Ground Floor</option>
                  <option>First Floor</option>
                  <option>Swimming Pool Area</option>
                  <option>Cardio Zone</option>
                  <option>Weight Training Area</option>
                  <option>Yoga Studio</option>
                  <option>Outdoor Area</option>
                </select>
              </div>

              <div>
                <label className="text-sm font-semibold text-gray-700 block mb-1.5">⏱️ Session Duration</label>
                <select value={sessionDuration} onChange={e => setSessionDuration(e.target.value)}
                  className="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 focus:border-[#E8845C] cursor-pointer">
                  <option>30 minutes</option>
                  <option>45 minutes</option>
                  <option>60 minutes</option>
                  <option>90 minutes</option>
                  <option>120 minutes</option>
                </select>
              </div>

              <div>
                <label className="text-sm font-semibold text-gray-700 block mb-1.5">📝 Session Notes (optional)</label>
                <textarea value={sessionNotes} onChange={e => setSessionNotes(e.target.value)} placeholder="e.g. Bring workout clothes, focus on assessment today" rows={2}
                  className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 focus:border-[#E8845C] resize-none" />
              </div>

              <div>
                <label className="text-sm font-semibold text-gray-700 block mb-1.5">💬 Message to Member (optional)</label>
                <textarea value={adminNote} onChange={e => setAdminNote(e.target.value)} placeholder="e.g. Your trainer will contact you soon to confirm" rows={2}
                  className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 focus:border-[#E8845C] resize-none" />
              </div>
            </div>
            <div className="p-6 border-t border-gray-100 shrink-0 flex gap-3">
              <button onClick={() => { setSelectedRequest(null); resetForm(); }}
                className="flex-1 py-2.5 border border-gray-200 rounded-xl text-sm text-gray-600 hover:bg-gray-50 font-semibold transition-colors">
                Cancel
              </button>
              <button onClick={() => handleAction(selectedRequest.id, 'approved')} disabled={isUpdating || !sessionDate || !sessionTime}
                className="flex-1 py-2.5 bg-gradient-to-r from-[#7CB342] to-[#558B2F] text-white rounded-xl text-sm font-semibold transition-all disabled:opacity-50 flex items-center justify-center gap-2">
                {isUpdating ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : <CheckCircle size={15} />}
                Approve & Schedule
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
