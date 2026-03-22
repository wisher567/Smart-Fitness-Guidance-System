import React, { useState, useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import { 
  Send, Paperclip, Smile, MoreVertical, 
  Search, Phone, Video, Info, User,
  Check, CheckCheck, Clock, MessageCircle
} from 'lucide-react';
import api from '../../services/api';
import Avatar from '../../components/ui/Avatar';
import Badge from '../../components/ui/Badge';
import LoadingSpinner from '../../components/ui/LoadingSpinner';
import { useAuth } from '../../context/AuthContext';
import { format } from 'date-fns';
import { toast } from 'react-hot-toast';

export default function TrainerChat() {
  const { user: trainer } = useAuth();
  const [searchParams] = useSearchParams();
  const initialClientUid = searchParams.get('client');

  const [loading, setLoading] = useState(true);
  const [clients, setClients] = useState([]);
  const [selectedClient, setSelectedClient] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const messagesEndRef = useRef(null);

  useEffect(() => {
    fetchChatClients();
  }, []);

  useEffect(() => {
    if (selectedClient) {
      fetchChatHistory(selectedClient.uid);
    }
  }, [selectedClient]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const fetchChatClients = async () => {
    try {
      const res = await api.get('/trainer/chat/clients');
      if (res.data.success) {
        setClients(res.data.clients);
        if (initialClientUid) {
          const client = res.data.clients.find(c => c.uid === initialClientUid);
          if (client) setSelectedClient(client);
        } else if (res.data.clients.length > 0) {
          setSelectedClient(res.data.clients[0]);
        }
      }
    } catch (err) {
      console.error('Failed to fetch chat clients:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchChatHistory = async (clientUid) => {
    try {
      const res = await api.get(`/trainer/chat/${clientUid}`);
      if (res.data.success) {
        setMessages(res.data.messages);
      }
    } catch (err) {
      console.error('Failed to fetch chat history:', err);
    }
  };

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim() || !selectedClient) return;

    const tempMessage = {
      id: Date.now(),
      senderId: trainer.uid,
      message: newMessage,
      createdAt: new Date().toISOString(),
      sending: true
    };

    setMessages([...messages, tempMessage]);
    setNewMessage('');

    try {
      const res = await api.post(`/trainer/chat/${selectedClient.uid}`, { message: tempMessage.message });
      if (res.data.success) {
         setMessages(prev => prev.map(m => m.id === tempMessage.id ? { ...tempMessage, sending: false } : m));
      }
    } catch (err) {
      toast.error('Failed to send message');
      setMessages(prev => prev.filter(m => m.id !== tempMessage.id));
    }
  };

  const filteredClients = clients.filter(c => 
    c.name?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (loading) return <LoadingSpinner />;

  return (
    <div className="h-[calc(100vh-140px)] flex bg-white rounded-[2.5rem] shadow-sm border border-gray-50 overflow-hidden animate-fade-in font-primary">
      {/* Sidebar: Client List */}
      <div className="w-full md:w-[350px] border-r border-gray-50 flex flex-col bg-gray-50/30">
        <div className="p-6">
          <h2 className="text-xl font-black text-gray-900 mb-6 flex items-center gap-2">
            Messages
            <Badge status="active" />
          </h2>
          <div className="relative">
             <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
             <input 
              type="text"
              placeholder="Search clients..."
              className="w-full pl-11 pr-4 py-3 bg-white border border-gray-100 rounded-2xl focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 focus:border-[#E8845C] transition-all text-sm font-medium"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
             />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto space-y-1 px-3 pb-6">
           {filteredClients.length > 0 ? (
             filteredClients.map((client) => (
               <button
                key={client.uid}
                onClick={() => setSelectedClient(client)}
                className={`w-full flex items-center gap-4 p-4 rounded-3xl transition-all group
                  ${selectedClient?.uid === client.uid 
                    ? 'bg-white shadow-md border border-orange-100' 
                    : 'hover:bg-white/50 border border-transparent'}`}
               >
                 <div className="relative shrink-0">
                    <Avatar name={client.name} size="md" />
                    {client.online && <div className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 bg-green-500 border-2 border-white rounded-full"></div>}
                 </div>
                 <div className="flex-1 min-w-0 text-left">
                    <div className="flex justify-between items-baseline mb-0.5">
                       <h3 className={`text-sm font-bold truncate ${selectedClient?.uid === client.uid ? 'text-[#E8845C]' : 'text-gray-900'}`}>
                          {client.name}
                       </h3>
                       <span className="text-[10px] font-bold text-gray-400 uppercase tracking-tighter">12:45 PM</span>
                    </div>
                    <p className="text-xs text-gray-400 truncate font-medium">Click to chat with client...</p>
                 </div>
               </button>
             ))
           ) : (
             <div className="p-10 text-center text-gray-400 italic text-sm">No clients found.</div>
           )}
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col bg-white">
         {selectedClient ? (
           <>
              {/* Chat Header */}
              <div className="px-8 py-5 border-b border-gray-50 flex items-center justify-between shadow-sm bg-white z-10">
                 <div className="flex items-center gap-4">
                    <Avatar name={selectedClient.name} size="md" />
                    <div>
                       <h3 className="font-extrabold text-gray-900 leading-none mb-1">{selectedClient.name}</h3>
                       <div className="flex items-center gap-1.5">
                          <div className="w-1.5 h-1.5 rounded-full bg-green-500"></div>
                          <p className="text-[10px] text-gray-400 font-bold uppercase tracking-widest">Active Now</p>
                       </div>
                    </div>
                 </div>
                 <div className="flex items-center gap-2">
                    <button className="p-2.5 text-gray-400 hover:text-[#E8845C] hover:bg-orange-50 rounded-xl transition-all"><Phone size={20} /></button>
                    <button className="p-2.5 text-gray-400 hover:text-[#E8845C] hover:bg-orange-50 rounded-xl transition-all"><Video size={20} /></button>
                    <div className="w-px h-6 bg-gray-100 mx-1"></div>
                    <button className="p-2.5 text-gray-400 hover:text-[#E8845C] hover:bg-orange-50 rounded-xl transition-all"><Info size={20} /></button>
                 </div>
              </div>

              {/* Messages Container */}
              <div className="flex-1 overflow-y-auto p-8 space-y-6 scrollbar-thin">
                 {messages.length > 0 ? (
                   messages.map((msg, idx) => {
                     const isTrainer = msg.senderId === trainer.uid;
                     const showDate = idx === 0 || format(new Date(messages[idx-1].createdAt), 'yyyy-MM-dd') !== format(new Date(msg.createdAt), 'yyyy-MM-dd');

                     return (
                       <div key={msg.id || idx} className="space-y-4">
                          {showDate && (
                            <div className="flex justify-center my-6">
                               <span className="bg-gray-100 text-gray-400 text-[10px] font-black px-4 py-1.5 rounded-full uppercase tracking-widest border border-gray-50">
                                  {format(new Date(msg.createdAt), 'MMMM d, yyyy')}
                               </span>
                            </div>
                          )}
                          <div className={`flex ${isTrainer ? 'justify-end' : 'justify-start'}`}>
                             <div className={`max-w-[70%] flex flex-col ${isTrainer ? 'items-end' : 'items-start'}`}>
                                <div className={`p-4 rounded-3xl shadow-sm relative group
                                   ${isTrainer 
                                     ? 'bg-[#0F1923] text-white rounded-tr-none' 
                                     : 'bg-gray-50 text-gray-800 rounded-tl-none border border-gray-100'}`}>
                                   <p className="text-sm font-medium leading-relaxed">{msg.message}</p>
                                </div>
                                <div className="flex items-center gap-1.5 mt-1.5 px-1">
                                   <span className="text-[9px] font-bold text-gray-400 uppercase tracking-tighter">
                                      {format(new Date(msg.createdAt), 'h:mm a')}
                                   </span>
                                   {isTrainer && (
                                     msg.sending ? <Clock size={10} className="text-gray-300 animate-pulse" /> : <CheckCheck size={12} className="text-[#E8845C]" />
                                   )}
                                </div>
                             </div>
                          </div>
                       </div>
                     );
                   })
                 ) : (
                   <div className="flex flex-col items-center justify-center h-full text-center gap-3">
                      <div className="bg-gray-50 p-6 rounded-full text-gray-200">
                        <User size={48} />
                      </div>
                      <p className="text-gray-400 font-medium italic">No messages yet. Send a greeting to start the conversation!</p>
                   </div>
                 )}
                 <div ref={messagesEndRef} />
              </div>

              {/* Message Input Area */}
              <div className="p-6 bg-white border-t border-gray-50">
                 <form onSubmit={handleSendMessage} className="flex items-center gap-3 bg-gray-50 p-2 rounded-3xl border border-gray-100 focus-within:border-[#E8845C]/30 focus-within:ring-4 focus-within:ring-[#E8845C]/5 transition-all">
                    <button type="button" className="p-3 text-gray-400 hover:text-[#E8845C] transition-all"><Paperclip size={20} /></button>
                    <input 
                      type="text"
                      className="flex-1 bg-transparent py-3 px-1 text-sm font-bold focus:outline-none placeholder-gray-300"
                      placeholder="Type your message here..."
                      value={newMessage}
                      onChange={(e) => setNewMessage(e.target.value)}
                    />
                    <button type="button" className="p-3 text-gray-400 hover:text-[#E8845C] transition-all"><Smile size={20} /></button>
                    <button 
                      type="submit" 
                      className="bg-[#E8845C] text-white p-3.5 rounded-2xl shadow-lg shadow-orange-500/20 hover:scale-105 active:scale-95 transition-all disabled:opacity-50 disabled:scale-100"
                      disabled={!newMessage.trim()}
                    >
                       <Send size={20} className="ml-0.5" />
                    </button>
                 </form>
              </div>
           </>
         ) : (
           <div className="flex flex-col items-center justify-center h-full text-center gap-6 p-20 animate-slide-up">
              <div className="w-24 h-24 bg-orange-50 rounded-[3rem] flex items-center justify-center text-[#E8845C] shadow-lg shadow-orange-500/10">
                 <MessageCircle size={48} />
              </div>
              <div>
                 <h3 className="text-2xl font-black text-gray-900 mb-2">Select a Client</h3>
                 <p className="text-gray-500 max-w-xs mx-auto font-medium">Choose a client from the sidebar to view your conversation and share training tips.</p>
              </div>
           </div>
         )}
      </div>
    </div>
  );
}
