import { useState, useEffect } from 'react';
import { Plus, Edit2, Trash2, Mail, Phone, Star } from 'lucide-react';
import { toast } from 'react-hot-toast';
import api from '../services/api';
import Modal from '../components/ui/Modal';
import { getInitials, getAvatarColor, formatDate } from '../utils/formatters';

export default function Trainers() {
  const [trainers, setTrainers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingTrainer, setEditingTrainer] = useState(null);

  const [formData, setFormData] = useState({
    name: '', email: '', phone: '', specialization: '', experience: '', bio: ''
  });

  useEffect(() => {
    fetchTrainers();
  }, []);

  const fetchTrainers = async () => {
    try {
      const res = await api.get('/admin/trainers');
      setTrainers(res.data?.trainers || []);
    } catch (err) {
      toast.error('Failed to load trainers');
    } finally {
      setLoading(false);
    }
  };

  const openAddModal = () => {
    setEditingTrainer(null);
    setFormData({ name: '', email: '', phone: '', specialization: '', experience: '', bio: '' });
    setIsModalOpen(true);
  };

  const openEditModal = (t) => {
    setEditingTrainer(t);
    setFormData({
      name: t.name || '', email: t.email || '', phone: t.phone || '',
      specialization: t.specialization || '', experience: t.experience || '', bio: t.bio || ''
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this trainer?')) {
      try {
        await api.delete(`/admin/trainers/${id}`);
        setTrainers(trainers.filter(t => t.uid !== id));
        toast.success('Trainer removed');
      } catch (err) {
        toast.error('Failed to remove trainer');
      }
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editingTrainer) {
        await api.patch(`/admin/trainers/${editingTrainer.uid}`, formData);
        toast.success('Trainer details updated');
      } else {
        await api.post('/admin/trainers', { ...formData, role: 'trainer' });
        toast.success('Trainer added successfully');
      }
      setIsModalOpen(false);
      fetchTrainers();
    } catch (err) {
      toast.error(err.response?.data?.error || 'Failed to save trainer');
    }
  };

  const filteredTrainers = trainers.filter(t => 
    (t.name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (t.specialization || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6 animate-fade-in-up">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Gym Trainers</h2>
          <p className="text-gray-500 text-sm mt-1">Manage staff and trainer access</p>
        </div>
        <div className="flex flex-col sm:flex-row items-center gap-3 w-full sm:w-auto">
          <input 
            type="text" 
            placeholder="Search trainers..." 
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full sm:w-64 px-4 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors"
          />
          <button onClick={openAddModal} className="w-full sm:w-auto flex items-center justify-center gap-2 bg-primary hover:bg-primaryDark text-white font-semibold px-4 py-2.5 rounded-xl transition-colors">
            <Plus size={20} /> Add Trainer
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div></div>
      ) : filteredTrainers.length === 0 ? (
        <div className="bg-white rounded-2xl border border-dashed border-gray-300 p-12 text-center text-gray-500">
          No trainers found matching your search.
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filteredTrainers.map(t => (
            <div key={t.uid} className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden group hover:shadow-md transition-shadow">
              <div className="h-24 bg-gradient-to-r from-primary/80 to-primaryDark"></div>
              <div className="pt-0 p-6 flex flex-col items-center">
                <div className={`w-20 h-20 rounded-full border-4 border-white -mt-10 mb-3 shadow-sm flex items-center justify-center text-white text-2xl font-bold ${getAvatarColor(t.name)}`}>
                  {getInitials(t.name)}
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-1">{t.name}</h3>
                <p className="text-sm font-semibold text-primary mb-4">{t.specialization || 'General Fitness'}</p>
                
                <div className="w-full space-y-2 mb-6">
                  <div className="flex items-center gap-3 text-sm text-gray-600">
                    <Mail size={16} className="text-gray-400" /> <span className="truncate">{t.email}</span>
                  </div>
                  <div className="flex items-center gap-3 text-sm text-gray-600">
                    <Phone size={16} className="text-gray-400" /> <span>{t.phone || '—'}</span>
                  </div>
                  <div className="flex items-center gap-3 text-sm text-gray-600">
                    <Star size={16} className="text-gray-400" /> <span>{t.experience || '—'} Yrs Experience</span>
                  </div>
                </div>

                <div className="w-full flex justify-between items-center pt-4 border-t border-gray-100">
                  <p className="text-xs text-gray-400">Joined {formatDate(t.createdAt)}</p>
                  <div className="flex items-center gap-2">
                    <button onClick={() => openEditModal(t)} className="p-2 text-gray-400 hover:text-primary transition-colors bg-gray-50 hover:bg-primary/10 rounded-lg"><Edit2 size={16}/></button>
                    <button onClick={() => handleDelete(t.uid)} className="p-2 text-gray-400 hover:text-red-500 transition-colors bg-gray-50 hover:bg-red-50 rounded-lg"><Trash2 size={16}/></button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add/Edit Modal */}
      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingTrainer ? "Edit Trainer Profile" : "Add New Trainer"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
              <input type="text" required value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>
            
            <div className="col-span-2 sm:col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-1">Email <span className="text-xs text-gray-400 font-normal">(Used for login)</span></label>
              <input type="email" required disabled={!!editingTrainer} value={formData.email} onChange={e => setFormData({...formData, email: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 disabled:opacity-60" />
            </div>

            <div className="col-span-2 sm:col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
              <input type="text" value={formData.phone} onChange={e => setFormData({...formData, phone: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>

            <div className="col-span-2 sm:col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-1">Specialization</label>
              <input type="text" value={formData.specialization} onChange={e => setFormData({...formData, specialization: e.target.value})} placeholder="e.g. Yoga, Crossfit" className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>

            <div className="col-span-2 sm:col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-1">Years Experience</label>
              <input type="number" min="0" value={formData.experience} onChange={e => setFormData({...formData, experience: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>

            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Short Bio</label>
              <textarea value={formData.bio} onChange={e => setFormData({...formData, bio: e.target.value})} rows="3" className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>
            
            {!editingTrainer && (
              <div className="col-span-2 text-xs text-amber-600 bg-amber-50 p-3 rounded-lg border border-amber-200">
                <strong>Note:</strong> A default password will be sent to the trainer's email.
              </div>
            )}
          </div>

          <div className="flex justify-end gap-3 pt-4 border-t border-gray-100 mt-6">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-5 py-2.5 text-gray-700 font-medium hover:bg-gray-100 rounded-xl transition-colors">Cancel</button>
            <button type="submit" className="px-5 py-2.5 bg-primary hover:bg-primaryDark text-white font-semibold rounded-xl transition-colors">{editingTrainer ? 'Update Profile' : 'Add Trainer'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
