import React, { useState, useEffect } from 'react';
import api from '../services/api';
import toast from 'react-hot-toast';
import { MessageSquare, RefreshCw, Reply, User, Info, CheckCircle, Clock } from 'lucide-react';

export default function Messages() {
  const [messages, setMessages] = useState([]);
  const [stats, setStats] = useState({});
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('all');
  const [selectedMsg, setSelectedMsg] = useState(null);
  const [replyText, setReplyText] = useState('');
  const [isReplying, setIsReplying] = useState(false);

  useEffect(() => {
    fetchMessages();
  }, []);

  const fetchMessages = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/messages');
      setMessages(res.data.messages || []);
      setStats(res.data.stats || {});
    } catch (err) {
      toast.error('Failed to load messages');
    } finally {
      setIsLoading(false);
    }
  };

  const handleReply = async () => {
    if (!replyText.trim()) return toast.error('Reply cannot be empty');
    setIsReplying(true);
    try {
      await api.patch(`/admin/messages/${selectedMsg.id}`, { adminReply: replyText });
      toast.success('Reply sent successfully!');
      setReplyText('');
      setSelectedMsg(null);
      fetchMessages();
    } catch (err) {
      toast.error('Failed to send reply');
    } finally {
      setIsReplying(false);
    }
  };

  const filtered = messages.filter(m => {
    if (activeTab === 'open') return m.status === 'open';
    if (activeTab === 'replied') return m.status === 'replied';
    return true;
  });

  const categoryIcons = {
    general: '💬', billing: '💳', technical: '🔧', trainer: '👨‍💼', complaint: '⚠️', suggestion: '💡', membership: '🏋️'
  };

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-gray-900 flex items-center gap-3">
            <MessageSquare className="text-[#E8845C]" size={28} />
            Member Messages
            {stats.open > 0 && <span className="px-2.5 py-1 bg-amber-100 text-amber-600 text-sm rounded-full">{stats.open} open</span>}
          </h1>
          <p className="text-gray-500 mt-1 text-sm">Respond to member inquiries and support requests.</p>
        </div>
        <button onClick={fetchMessages} className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 text-sm text-gray-700">
          <RefreshCw size={16} /> Refresh
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-gray-100 flex justify-between items-center shadow-sm">
          <div><p className="text-gray-500 text-sm">Total Messages</p><p className="text-2xl font-bold">{stats.total || 0}</p></div>
          <div className="w-12 h-12 bg-gray-50 rounded-full flex items-center justify-center text-xl">📨</div>
        </div>
        <div className="bg-amber-50 p-5 rounded-2xl border border-amber-100 flex justify-between items-center shadow-sm">
          <div><p className="text-amber-800 text-sm">Pending Reply</p><p className="text-2xl font-bold text-amber-600">{stats.open || 0}</p></div>
          <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center text-xl">⏳</div>
        </div>
        <div className="bg-green-50 p-5 rounded-2xl border border-green-100 flex justify-between items-center shadow-sm">
          <div><p className="text-green-800 text-sm">Replied</p><p className="text-2xl font-bold text-green-600">{stats.replied || 0}</p></div>
          <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center text-xl">✅</div>
        </div>
      </div>

      <div className="bg-white border border-gray-100 rounded-2xl shadow-sm overflow-hidden p-1 flex w-fit">
        {['all', 'open', 'replied'].map(t => (
          <button key={t} onClick={() => setActiveTab(t)} className={`px-5 py-2 rounded-xl text-sm font-semibold capitalize ${activeTab === t ? 'bg-[#E8845C] text-white' : 'text-gray-500 hover:bg-gray-50'}`}>
            {t}
          </button>
        ))}
      </div>

      {isLoading ? (
        <div className="animate-pulse flex space-x-4">
          <div className="flex-1 space-y-4 py-1">
            <div className="h-24 bg-gray-200 rounded-xl"></div>
            <div className="h-24 bg-gray-200 rounded-xl"></div>
          </div>
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-3xl border border-gray-100">
          <CheckCircle size={48} className="mx-auto text-gray-300 mb-4" />
          <h3 className="text-gray-600 font-semibold mb-1">No messages found</h3>
          <p className="text-gray-400 text-sm">You're all caught up!</p>
        </div>
      ) : (
        <div className="space-y-4">
          {filtered.map(msg => (
            <div key={msg.id} className={`bg-white rounded-2xl border shadow-sm p-6 ${msg.status === 'open' ? 'border-[#E8845C]/30 hover:border-[#E8845C]' : 'border-gray-200'}`}>
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center text-xl font-bold text-gray-500">
                    {msg.memberName.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900">{msg.memberName}</h3>
                    <p className="text-sm text-gray-500">{msg.memberEmail}</p>
                  </div>
                </div>
                <div className="flex flex-col items-end gap-2">
                  <span className={`px-3 py-1 text-xs font-bold rounded-full ${msg.status === 'open' ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700'}`}>
                    {msg.status === 'open' ? '⏳ Pending' : '✅ Replied'}
                  </span>
                  <span className="text-xs text-gray-400 flex items-center gap-1">
                    <Clock size={12} /> {new Date(msg.createdAt).toLocaleDateString()}
                  </span>
                </div>
              </div>

              <div className="bg-gray-50 rounded-xl p-4 border border-gray-100">
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-lg">{categoryIcons[msg.category] || '💬'}</span>
                  <h4 className="font-semibold text-gray-900">{msg.subject}</h4>
                </div>
                <p className="text-gray-600 text-sm whitespace-pre-wrap">{msg.message}</p>
              </div>

              {/* Conversation thread */}
              {msg.replies && msg.replies.length > 0 ? (
                <div className="mt-4 space-y-3">
                  <p className="text-xs font-bold text-gray-500 uppercase">Conversation</p>
                  {msg.replies.map((r, i) => (
                    <div key={i} className={`rounded-xl p-4 border ${r.from === 'admin' ? 'bg-[#F0FDF4] border-green-200' : 'bg-orange-50 border-orange-200'}`}>
                      <div className="flex items-center gap-2 mb-1">
                        {r.from === 'admin' ? (
                          <CheckCircle size={14} className="text-green-600" />
                        ) : (
                          <User size={14} className="text-orange-600" />
                        )}
                        <span className={`font-semibold text-sm ${r.from === 'admin' ? 'text-green-800' : 'text-orange-800'}`}>
                          {r.from === 'admin' ? 'Admin Reply' : 'Member Reply'}
                        </span>
                        <span className="text-xs text-gray-400 ml-auto">
                          {r.createdAt ? new Date(r.createdAt).toLocaleString() : ''}
                        </span>
                      </div>
                      <p className={`text-sm whitespace-pre-wrap ${r.from === 'admin' ? 'text-green-900' : 'text-orange-900'}`}>{r.text}</p>
                    </div>
                  ))}
                </div>
              ) : msg.adminReply ? (
                <div className="mt-4 bg-[#F0FDF4] rounded-xl p-4 border border-green-200">
                  <div className="flex items-center gap-2 mb-1">
                    <CheckCircle size={16} className="text-green-600" />
                    <span className="font-semibold text-green-800 text-sm">Your Reply</span>
                  </div>
                  <p className="text-green-900 text-sm whitespace-pre-wrap">{msg.adminReply}</p>
                </div>
              ) : null}

              {msg.status === 'open' && (
                <div className="mt-4 flex justify-end">
                  <button onClick={() => setSelectedMsg(msg)} className="flex items-center gap-2 px-5 py-2.5 bg-[#1E2A3B] text-white rounded-xl hover:bg-[#2D3F56] transition-colors text-sm font-semibold">
                    <Reply size={16} /> Reply to Member
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {selectedMsg && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setSelectedMsg(null)} />
          <div className="relative bg-white rounded-3xl p-6 w-full max-w-lg shadow-2xl animate-scale-up">
            <h2 className="text-xl font-bold mb-4 font-display">Reply to {selectedMsg.memberName}</h2>
            
            <div className="bg-gray-50 p-4 rounded-xl border border-gray-100 mb-4">
              <p className="text-xs text-gray-500 font-bold mb-1">ORIGINAL MESSAGE:</p>
              <p className="text-sm text-gray-800">{selectedMsg.message}</p>
            </div>

            <textarea
              className="w-full h-32 p-4 bg-white border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#E8845C] focus:border-[#E8845C] resize-none mb-4"
              placeholder="Type your response here. This will be emailed directly to the member..."
              value={replyText}
              onChange={e => setReplyText(e.target.value)}
            />

            <div className="flex justify-end gap-3">
              <button disabled={isReplying} onClick={() => setSelectedMsg(null)} className="px-5 py-2.5 text-gray-600 font-semibold hover:bg-gray-100 rounded-xl">
                Cancel
              </button>
              <button disabled={isReplying} onClick={handleReply} className="flex items-center gap-2 px-5 py-2.5 bg-[#E8845C] text-white rounded-xl hover:bg-[#D4673A] font-semibold">
                {isReplying ? 'Sending...' : <><Reply size={16} /> Send Reply</>}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
