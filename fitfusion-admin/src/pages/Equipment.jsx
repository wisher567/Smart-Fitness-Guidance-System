import { useState, useEffect } from 'react';
import { Wrench, AlertTriangle, CheckCircle, Clock, 
         RefreshCw, Trash2, MessageSquare, Image } from 'lucide-react';
import api from '../services/api';
import Badge from '../components/ui/Badge';
import { formatDate, formatDateTime, getInitials } from '../utils/formatters';
import toast from 'react-hot-toast';

export default function Equipment() {
  const [alerts, setAlerts]         = useState([]);
  const [stats, setStats]           = useState({});
  const [activeTab, setActiveTab]   = useState('all');
  const [isLoading, setIsLoading]   = useState(true);
  const [selectedAlert, setSelectedAlert] = useState(null);
  const [adminNote, setAdminNote]   = useState('');
  const [isUpdating, setIsUpdating] = useState(false);
  const [showImage, setShowImage]   = useState(false);

  useEffect(() => {
    fetchAlerts();
    // Auto refresh every 30 seconds
    const interval = setInterval(fetchAlerts, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchAlerts = async () => {
    try {
      const res = await api.get('/admin/alerts');
      setAlerts(res.data.alerts || []);
      setStats(res.data.stats || {});
    } catch (err) {
      toast.error('Failed to load alerts');
    } finally {
      setIsLoading(false);
    }
  };

  const updateStatus = async (id, status) => {
    setIsUpdating(true);
    try {
      await api.patch(`/admin/alerts/${id}`, { 
        status, 
        adminNotes: adminNote 
      });
      toast.success(`Marked as ${status.replace('_', ' ')}`);
      setSelectedAlert(null);
      setAdminNote('');
      await fetchAlerts();
    } catch {
      toast.error('Failed to update status');
    } finally {
      setIsUpdating(false);
    }
  };

  const deleteAlert = async (id) => {
    if (!confirm('Delete this alert?')) return;
    try {
      await api.delete(`/admin/alerts/${id}`);
      toast.success('Alert deleted');
      await fetchAlerts();
    } catch {
      toast.error('Failed to delete');
    }
  };

  const filteredAlerts = alerts.filter(a => {
    if (activeTab === 'all') return true;
    return a.status === activeTab;
  });

  const tabs = [
    { key: 'all',        label: 'All',         count: stats.total       },
    { key: 'open',       label: 'Open',        count: stats.open        },
    { key: 'in_progress',label: 'In Progress', count: stats.in_progress },
    { key: 'resolved',   label: 'Resolved',    count: stats.resolved    },
  ];

  return (
    <div className="p-6 lg:p-8 space-y-6 animate-fade-in">
      
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            Equipment Alerts
            {stats.open > 0 && (
              <span className="px-2 py-0.5 bg-red-100 text-red-600 
                text-sm font-bold rounded-xl animate-pulse">
                {stats.open} open
              </span>
            )}
          </h1>
          <p className="text-gray-500 text-sm mt-1">
            Member reported equipment issues
          </p>
        </div>
        <button onClick={fetchAlerts}
          className="flex items-center gap-2 px-4 py-2.5 bg-white 
            border border-gray-200 rounded-xl text-sm text-gray-600 
            hover:bg-gray-50 shadow-card transition-all">
          <RefreshCw size={15} />
          Refresh
        </button>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Total Open',    value: stats.open        || 0, 
            color: 'bg-red-50',    text: 'text-red-600',    icon: '🚨' },
          { label: 'In Progress',   value: stats.in_progress || 0, 
            color: 'bg-amber-50',  text: 'text-amber-600',  icon: '🔧' },
          { label: 'Resolved',      value: stats.resolved    || 0, 
            color: 'bg-green-50',  text: 'text-green-600',  icon: '✅' },
          { label: 'High Priority', value: stats.high        || 0, 
            color: 'bg-orange-50', text: 'text-orange-600', icon: '⚠️' },
        ].map(s => (
          <div key={s.label} className={`${s.color} rounded-2xl p-4 
            border border-white/50`}>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xl">{s.icon}</span>
              <span className={`text-2xl font-bold ${s.text}`}>
                {s.value}
              </span>
            </div>
            <p className={`text-sm font-medium ${s.text}`}>{s.label}</p>
          </div>
        ))}
      </div>

      {/* Tab filter */}
      <div className="bg-white rounded-2xl border border-gray-100 
        shadow-card p-1 flex gap-1 w-fit">
        {tabs.map(tab => (
          <button key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl 
              text-sm font-medium transition-all
              ${activeTab === tab.key
                ? 'bg-[#E8845C] text-white shadow-sm'
                : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
              }`}>
            {tab.label}
            {tab.count > 0 && (
              <span className={`text-xs px-1.5 py-0.5 rounded-full
                font-bold
                ${activeTab === tab.key
                  ? 'bg-white/20 text-white'
                  : 'bg-gray-100 text-gray-500'
                }`}>
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Alerts List */}
      {isLoading ? (
        <div className="space-y-3">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-white rounded-2xl border 
              border-gray-100 p-6 animate-pulse">
              <div className="flex gap-4">
                <div className="w-10 h-10 bg-gray-100 rounded-xl" />
                <div className="flex-1 space-y-2">
                  <div className="h-4 bg-gray-100 rounded w-1/3" />
                  <div className="h-3 bg-gray-100 rounded w-2/3" />
                  <div className="h-3 bg-gray-100 rounded w-1/4" />
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : filteredAlerts.length === 0 ? (
        <div className="bg-white rounded-2xl border border-gray-100 
          shadow-card flex flex-col items-center justify-center py-16">
          <div className="w-16 h-16 bg-gray-50 rounded-2xl flex 
            items-center justify-center mb-4">
            <CheckCircle size={28} className="text-green-300" />
          </div>
          <h3 className="text-gray-700 font-semibold mb-1">
            No alerts here!
          </h3>
          <p className="text-gray-400 text-sm">
            {activeTab === 'open' 
              ? 'All equipment is in good shape 💪' 
              : 'Nothing to show for this filter'}
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {filteredAlerts.map(alert => (
            <div key={alert.id}
              className="bg-white rounded-2xl border border-gray-100 
                shadow-card hover:shadow-cardHover transition-all 
                duration-200 overflow-hidden">
              
              {/* Urgency indicator bar */}
              <div className={`h-1 w-full ${
                alert.urgency === 'high'   ? 'bg-red-500' :
                alert.urgency === 'medium' ? 'bg-orange-400' : 
                'bg-yellow-400'
              }`} />

              <div className="p-5">
                <div className="flex items-start gap-4">
                  
                  {/* Icon */}
                  <div className={`p-3 rounded-2xl shrink-0 ${
                    alert.urgency === 'high'   ? 'bg-red-50'    :
                    alert.urgency === 'medium' ? 'bg-orange-50' : 
                    'bg-yellow-50'
                  }`}>
                    <Wrench size={18} className={
                      alert.urgency === 'high'   ? 'text-red-500'    :
                      alert.urgency === 'medium' ? 'text-orange-500' : 
                      'text-yellow-500'
                    } />
                  </div>

                  {/* Content */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-3 
                      flex-wrap">
                      <div>
                        <h3 className="font-bold text-gray-900 text-base">
                          {alert.equipment}
                        </h3>
                        <p className="text-gray-600 text-sm mt-0.5">
                          {alert.issue}
                        </p>
                        {alert.description && (
                          <p className="text-gray-400 text-xs mt-1 
                            line-clamp-2">
                            {alert.description}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center gap-2 shrink-0">
                        <Badge status={alert.urgency} />
                        <Badge status={alert.status} />
                      </div>
                    </div>

                    {/* Meta info */}
                    <div className="flex flex-wrap items-center gap-4 
                      mt-3 text-xs text-gray-400">
                      <div className="flex items-center gap-1.5">
                        <div className="w-5 h-5 bg-gradient-to-br 
                          from-[#E8845C] to-[#D4673A] rounded-lg 
                          flex items-center justify-center text-white 
                          text-[9px] font-bold">
                          {getInitials(alert.reportedByName)}
                        </div>
                        {alert.reportedByName}
                      </div>
                      {alert.location && (
                        <span>📍 {alert.location}</span>
                      )}
                      <span>🕐 {formatDateTime(alert.createdAt)}</span>
                      {alert.imageBase64 && (
                        <button
                          onClick={() => {
                            setSelectedAlert(alert);
                            setShowImage(true);
                          }}
                          className="flex items-center gap-1 
                            text-[#E8845C] font-medium hover:underline">
                          <Image size={12} />
                          View Photo
                        </button>
                      )}
                    </div>

                    {/* Admin notes (if any) */}
                    {alert.adminNotes && (
                      <div className="mt-3 p-3 bg-green-50 rounded-xl 
                        border border-green-100">
                        <p className="text-xs text-green-600 font-semibold 
                          mb-1">Admin Response:</p>
                        <p className="text-xs text-green-700">
                          {alert.adminNotes}
                        </p>
                      </div>
                    )}

                    {/* Action buttons */}
                    {alert.status !== 'resolved' && (
                      <div className="flex flex-wrap items-center gap-2 mt-4">
                        {alert.status === 'open' && (
                          <button
                            onClick={() => updateStatus(alert.id, 'in_progress')}
                            className="flex items-center gap-1.5 px-3 py-1.5
                              bg-amber-50 border border-amber-100 text-amber-700
                              rounded-xl text-xs font-semibold hover:bg-amber-100
                              transition-colors">
                            <Clock size={13} />
                            Mark In Progress
                          </button>
                        )}
                        <button
                          onClick={() => setSelectedAlert(alert)}
                          className="flex items-center gap-1.5 px-3 py-1.5
                            bg-green-50 border border-green-100 text-green-700
                            rounded-xl text-xs font-semibold hover:bg-green-100
                            transition-colors">
                          <CheckCircle size={13} />
                          Mark Resolved
                        </button>
                        <button
                          onClick={() => deleteAlert(alert.id)}
                          className="flex items-center gap-1.5 px-3 py-1.5
                            bg-red-50 border border-red-100 text-red-600
                            rounded-xl text-xs font-semibold hover:bg-red-100
                            transition-colors ml-auto">
                          <Trash2 size={13} />
                          Delete
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Resolve Modal */}
      {selectedAlert && !showImage && (
        <div className="fixed inset-0 z-50 flex items-center 
          justify-center p-4">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={() => setSelectedAlert(null)} />
          <div className="relative bg-white rounded-3xl shadow-modal 
            w-full max-w-md border border-gray-100 animate-slide-up">
            <div className="p-6 border-b border-gray-100">
              <h3 className="font-bold text-gray-900 text-lg">
                Resolve Alert
              </h3>
              <p className="text-gray-500 text-sm mt-1">
                {selectedAlert.equipment} — {selectedAlert.issue}
              </p>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="text-sm font-medium text-gray-700 
                  block mb-2">
                  Resolution Notes (optional)
                </label>
                <textarea
                  value={adminNote}
                  onChange={e => setAdminNote(e.target.value)}
                  placeholder="e.g. Belt replaced, equipment is working fine now"
                  rows={3}
                  className="w-full px-4 py-3 bg-gray-50 border 
                    border-gray-200 rounded-xl text-sm text-gray-700
                    placeholder-gray-400 focus:outline-none 
                    focus:ring-2 focus:ring-[#E8845C]/20 
                    focus:border-[#E8845C] resize-none"
                />
                <p className="text-xs text-gray-400 mt-1">
                  This message will be visible to the member who reported it.
                </p>
              </div>
            </div>
            <div className="p-6 border-t border-gray-100 flex gap-3">
              <button
                onClick={() => setSelectedAlert(null)}
                className="flex-1 py-2.5 border border-gray-200 
                  rounded-xl text-sm text-gray-600 hover:bg-gray-50 
                  font-semibold transition-colors">
                Cancel
              </button>
              <button
                onClick={() => updateStatus(selectedAlert.id, 'resolved')}
                disabled={isUpdating}
                className="flex-1 py-2.5 bg-gradient-to-r 
                  from-[#E8845C] to-[#D4673A] text-white rounded-xl 
                  text-sm font-semibold hover:shadow-button 
                  transition-all disabled:opacity-50 
                  flex items-center justify-center gap-2">
                {isUpdating ? (
                  <div className="w-4 h-4 border-2 border-white/30 
                    border-t-white rounded-full animate-spin" />
                ) : (
                  <CheckCircle size={15} />
                )}
                Mark as Resolved
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Image Modal */}
      {selectedAlert && showImage && selectedAlert.imageBase64 && (
        <div className="fixed inset-0 z-50 flex items-center 
          justify-center p-4 bg-black/80"
          onClick={() => { setShowImage(false); setSelectedAlert(null); }}>
          <div className="max-w-lg w-full animate-fade-in">
            <img
              src={`data:image/jpeg;base64,${selectedAlert.imageBase64}`}
              alt="Equipment issue"
              className="w-full rounded-2xl shadow-2xl"
            />
            <p className="text-white text-center text-sm mt-3 opacity-70">
              {selectedAlert.equipment} — Tap anywhere to close
            </p>
          </div>
        </div>
      )}

    </div>
  );
}
