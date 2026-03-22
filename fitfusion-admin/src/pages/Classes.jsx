import { useState, useEffect } from 'react';
import { Calendar as CalendarIcon, List, Plus, Clock, MapPin, Users, Edit2, Trash2 } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { format, startOfWeek, addDays, isSameDay, parseISO } from 'date-fns';
import api from '../services/api';
import Modal from '../components/ui/Modal';
import DataTable from '../components/ui/DataTable';

export default function Classes() {
  const [classes, setClasses] = useState([]);
  const [trainers, setTrainers] = useState([]);
  const [viewMode, setViewMode] = useState('calendar'); // 'calendar' or 'list'
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingClass, setEditingClass] = useState(null);

  const [formData, setFormData] = useState({
    name: '', trainer: '', trainerId: '', date: '', time: '', duration: 60, capacity: 20, location: '', description: ''
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [classRes, trainersRes] = await Promise.all([
        api.get('/admin/classes'),
        api.get('/admin/trainers').catch(() => ({ data: { trainers: [] } }))
      ]);
      setClasses(classRes.data?.classes || []);
      setTrainers(trainersRes.data?.trainers || []);
    } catch (err) {
      toast.error('Failed to load classes');
    } finally {
      setLoading(false);
    }
  };

  const openAddModal = (defaultDate = '') => {
    setEditingClass(null);
    setFormData({ name: '', trainer: trainers[0]?.name || '', trainerId: trainers[0]?.id || '', date: defaultDate, time: '09:00', duration: 60, capacity: 20, location: 'Studio A', description: '' });
    setIsModalOpen(true);
  };

  const openEditModal = (cls) => {
    setEditingClass(cls);
    setFormData({
      name: cls.name, trainer: cls.trainer, trainerId: cls.trainerId || '', date: cls.date, time: cls.time, 
      duration: cls.duration, capacity: cls.capacity, location: cls.location, description: cls.description || ''
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to cancel this class?')) {
      try {
        await api.delete(`/admin/classes/${id}`);
        setClasses(classes.filter(c => c.id !== id));
        toast.success('Class cancelled');
      } catch (err) {
        toast.error('Failed to cancel class');
      }
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = { ...formData, enrolled: editingClass?.enrolled || 0 };
      if (editingClass) {
        await api.patch(`/admin/classes/${editingClass.id}`, payload);
        toast.success('Class updated');
      } else {
        await api.post('/admin/classes', payload);
        toast.success('Class created');
      }
      setIsModalOpen(false);
      fetchData();
    } catch (err) {
      toast.error('Failed to save class');
    }
  };

  const startDate = startOfWeek(new Date(), { weekStartsOn: 1 });
  const weekDays = Array.from({ length: 7 }).map((_, i) => addDays(startDate, i));

  const columns = [
    { key: 'name', label: 'Class Name', render: (c) => <span className="font-bold text-gray-900">{c.name}</span> },
    { key: 'trainer', label: 'Trainer', render: (c) => c.trainer },
    { key: 'datetime', label: 'Date & Time', render: (c) => `${format(parseISO(c.date || new Date().toISOString()), 'MMM d, yyyy')} at ${c.time}` },
    { key: 'duration', label: 'Duration', render: (c) => `${c.duration} min` },
    { key: 'capacity', label: 'Capacity', render: (c) => (
      <div className="flex items-center gap-2">
        <div className="w-16 h-2 bg-gray-100 rounded-full overflow-hidden">
          <div className="h-full bg-primary" style={{ width: `${(c.enrolled / c.capacity) * 100}%` }}></div>
        </div>
        <span className="text-xs font-medium text-gray-600">{c.enrolled||0}/{c.capacity}</span>
      </div>
    )},
    { key: 'location', label: 'Location', render: (c) => c.location },
    { key: 'actions', label: '', render: (c) => (
      <div className="flex items-center gap-2">
        <button onClick={() => openEditModal(c)} className="p-1.5 text-gray-400 hover:text-primary transition-colors"><Edit2 size={16}/></button>
        <button onClick={() => handleDelete(c.id)} className="p-1.5 text-gray-400 hover:text-red-500 transition-colors"><Trash2 size={16}/></button>
      </div>
    )}
  ];

  return (
    <div className="space-y-6 animate-fade-in-up">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <h2 className="text-2xl font-bold text-gray-900">Class Schedule</h2>
        <div className="flex items-center gap-3">
          <div className="bg-white border border-gray-200 rounded-xl p-1 flex items-center">
            <button onClick={() => setViewMode('calendar')} className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${viewMode === 'calendar' ? 'bg-primary/10 text-primary' : 'text-gray-500 hover:text-gray-900'}`}>
              <CalendarIcon size={16} /> <span className="hidden sm:inline">Calendar</span>
            </button>
            <button onClick={() => setViewMode('list')} className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${viewMode === 'list' ? 'bg-primary/10 text-primary' : 'text-gray-500 hover:text-gray-900'}`}>
              <List size={16} /> <span className="hidden sm:inline">List</span>
            </button>
          </div>
          <button onClick={() => openAddModal()} className="flex items-center justify-center gap-2 bg-primary hover:bg-primaryDark text-white font-semibold px-4 py-2.5 rounded-xl transition-colors">
            <Plus size={20} /> Schedule Class
          </button>
        </div>
      </div>

      {viewMode === 'calendar' ? (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="grid grid-cols-7 border-b border-gray-100 bg-gray-50/50">
            {weekDays.map(day => (
              <div key={day.toISOString()} className="px-4 py-3 text-center border-r border-gray-100 last:border-0">
                <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{format(day, 'EEE')}</p>
                <p className={`text-lg font-bold mt-0.5 ${isSameDay(day, new Date()) ? 'text-primary' : 'text-gray-900'}`}>{format(day, 'd')}</p>
              </div>
            ))}
          </div>
          <div className="grid grid-cols-7 min-h-[500px]">
            {weekDays.map(day => {
              const dayClasses = classes.filter(c => c.date === format(day, 'yyyy-MM-dd')).sort((a,b) => a.time.localeCompare(b.time));
              return (
                <div key={day.toISOString()} className="border-r border-gray-100 last:border-0 relative p-2 group hover:bg-gray-50/50 transition-colors">
                  <button onClick={() => openAddModal(format(day, 'yyyy-MM-dd'))} className="absolute inset-0 w-full h-full opacity-0 group-hover:opacity-100 flex items-center justify-center bg-gray-50/80 z-0 transition-opacity">
                    <div className="w-8 h-8 rounded-full bg-white shadow flex items-center justify-center text-primary"><Plus size={20}/></div>
                  </button>
                  <div className="relative z-10 space-y-2">
                    {dayClasses.map(c => (
                      <div key={c.id} onClick={() => openEditModal(c)} className="bg-blue-50 border border-blue-100 rounded-lg p-2 cursor-pointer hover:shadow-md transition-all group/card">
                        <p className="text-xs font-bold text-blue-900 mb-1">{c.time}</p>
                        <p className="text-xs font-semibold text-blue-800 leading-tight">{c.name}</p>
                        <p className="text-[10px] text-blue-600 mt-1 truncate">{c.trainer}</p>
                      </div>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      ) : (
        <DataTable columns={columns} data={classes} loading={loading} emptyMessage="No classes scheduled." />
      )}

      {/* Add/Edit Modal */}
      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingClass ? "Edit Class" : "Schedule New Class"}>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Class Name</label>
              <input type="text" required value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" placeholder="e.g. HIIT Blast" />
            </div>
            
            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Trainer</label>
              <select value={formData.trainerId} onChange={e => {
                const selectedTrainer = trainers.find(t => t.id === e.target.value);
                setFormData({
                  ...formData, 
                  trainerId: e.target.value,
                  trainer: selectedTrainer ? selectedTrainer.name : 'Unassigned'
                });
              }} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20">
                <option value="">Select a trainer</option>
                {trainers.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
                <option value="Unassigned">Assign later</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Date</label>
              <input type="date" required value={formData.date} onChange={e => setFormData({...formData, date: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Time</label>
              <input type="time" required value={formData.time} onChange={e => setFormData({...formData, time: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Duration (mins)</label>
              <input type="number" required min="15" step="15" value={formData.duration} onChange={e => setFormData({...formData, duration: Number(e.target.value)})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Max Capacity</label>
              <input type="number" required min="1" value={formData.capacity} onChange={e => setFormData({...formData, capacity: Number(e.target.value)})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>

            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Location</label>
              <input type="text" required value={formData.location} onChange={e => setFormData({...formData, location: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" placeholder="e.g. Studio A, Main Gym Floor" />
            </div>

            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
              <textarea value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} rows="2" className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-4 border-t border-gray-100">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-5 py-2.5 text-gray-700 font-medium hover:bg-gray-100 rounded-xl transition-colors">Cancel</button>
            <button type="submit" className="px-5 py-2.5 bg-primary hover:bg-primaryDark text-white font-semibold rounded-xl transition-colors">{editingClass ? 'Update Class' : 'Schedule Class'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
