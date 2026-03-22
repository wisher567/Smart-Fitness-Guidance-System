import { useState, useEffect } from 'react';
import { Plus, Edit2, Trash2, CheckCircle2 } from 'lucide-react';
import { toast } from 'react-hot-toast';
import api from '../services/api';
import Modal from '../components/ui/Modal';
import { formatCurrency } from '../utils/formatters';

export default function Plans() {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingPlan, setEditingPlan] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    name: '',
    price: '',
    duration: 'monthly',
    description: '',
    features: [''],
    color: 'bg-orange-500',
    isActive: true,
    isPopular: false
  });

  const presetColors = ['bg-orange-500', 'bg-blue-500', 'bg-purple-500', 'bg-green-500', 'bg-gray-800', 'bg-pink-500'];

  useEffect(() => {
    fetchPlans();
  }, []);

  const fetchPlans = async () => {
    try {
      const res = await api.get('/admin/plans');
      setPlans(res.data?.plans || []);
    } catch (err) {
      toast.error('Failed to load plans');
    } finally {
      setLoading(false);
    }
  };

  const openAddModal = () => {
    setEditingPlan(null);
    setFormData({
      name: '', price: '', duration: 'monthly', description: '',
      features: [''], color: 'bg-orange-500', isActive: true, isPopular: false
    });
    setIsModalOpen(true);
  };

  const openEditModal = (plan) => {
    setEditingPlan(plan);
    setFormData({
      name: plan.name || '',
      price: plan.price || '',
      duration: plan.duration || 'monthly',
      description: plan.description || '',
      features: plan.features?.length ? [...plan.features] : [''],
      color: plan.color || 'bg-orange-500',
      isActive: plan.isActive !== false,
      isPopular: plan.isPopular || false
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this plan? This cannot be undone.')) {
      try {
        await api.delete(`/admin/plans/${id}`);
        setPlans(plans.filter(p => p.id !== id));
        toast.success('Plan deleted successfully');
      } catch (err) {
        toast.error('Failed to delete plan');
      }
    }
  };

  const handleToggleActive = async (plan) => {
    try {
      const newStatus = !plan.isActive;
      await api.patch(`/admin/plans/${plan.id}`, { isActive: newStatus });
      setPlans(plans.map(p => p.id === plan.id ? { ...p, isActive: newStatus } : p));
      toast.success(`Plan ${newStatus ? 'activated' : 'deactivated'}`);
    } catch (err) {
      toast.error('Failed to update status');
    }
  };

  const handleFeatureChange = (index, value) => {
    const newFeatures = [...formData.features];
    newFeatures[index] = value;
    setFormData({ ...formData, features: newFeatures });
  };

  const addFeature = () => setFormData({ ...formData, features: [...formData.features, ''] });
  const removeFeature = (index) => {
    if (formData.features.length > 1) {
      setFormData({ ...formData, features: formData.features.filter((_, i) => i !== index) });
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = { ...formData, price: Number(formData.price), features: formData.features.filter(f => f.trim()) };
      
      if (editingPlan) {
        await api.patch(`/admin/plans/${editingPlan.id}`, payload);
        toast.success('Plan updated');
      } else {
        await api.post('/admin/plans', payload);
        toast.success('Plan created');
      }
      setIsModalOpen(false);
      fetchPlans();
    } catch (err) {
      toast.error('Failed to save plan');
    }
  };

  if (loading) return (
    <div className="flex h-[60vh] items-center justify-center">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
    </div>
  );

  return (
    <div className="space-y-6 animate-fade-in-up">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <h2 className="text-2xl font-bold text-gray-900">Membership Plans</h2>
        <button onClick={openAddModal} className="flex items-center justify-center gap-2 bg-primary hover:bg-primaryDark text-white font-semibold px-4 py-2.5 rounded-xl transition-colors">
          <Plus size={20} /> Add New Plan
        </button>
      </div>

      {plans.length === 0 ? (
        <div className="bg-white rounded-2xl border border-dashed border-gray-300 p-12 text-center">
          <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4 text-gray-400">
            <Plus size={32} />
          </div>
          <h3 className="text-lg font-bold text-gray-900 mb-1">No plans created yet</h3>
          <p className="text-gray-500 mb-6">Create your first membership plan to start enrolling members.</p>
          <button onClick={openAddModal} className="bg-primary hover:bg-primaryDark text-white font-medium px-6 py-2 rounded-xl transition-colors">
            Create Plan
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          {plans.map(plan => (
            <div key={plan.id} className={`bg-white rounded-2xl shadow-sm border ${plan.isPopular ? 'border-primary shadow-primary/10 scale-[1.02]' : 'border-gray-100'} overflow-hidden flex flex-col relative`}>
              {plan.isPopular && (
                <div className="bg-primary text-white text-xs font-bold uppercase tracking-wider text-center py-1">
                  Most Popular
                </div>
              )}
              <div className={`h-2 w-full ${plan.color || 'bg-gray-800'}`}></div>
              
              <div className="p-6 flex-1 flex flex-col">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-xl font-bold text-gray-900">{plan.name}</h3>
                    <p className="text-sm text-gray-500 mt-1">{plan.description || 'No description'}</p>
                  </div>
                  <span className={`px-2 py-1 rounded-full text-xs font-semibold ${plan.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'}`}>
                    {plan.isActive ? 'Active' : 'Inactive'}
                  </span>
                </div>

                <div className="mb-6 flex items-baseline gap-1">
                  <span className="text-3xl font-bold text-gray-900">{formatCurrency(plan.price)}</span>
                  <span className="text-gray-500 font-medium">/{plan.duration === 'yearly' ? 'yr' : 'mo'}</span>
                </div>

                <div className="flex-1">
                  <p className="text-sm font-semibold text-gray-900 mb-3 uppercase tracking-wider">Features</p>
                  <ul className="space-y-3">
                    {plan.features?.map((f, i) => (
                      <li key={i} className="flex gap-3 text-sm text-gray-600">
                        <CheckCircle2 size={18} className="text-green-500 shrink-0 mt-0.5" />
                        <span>{f}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <div className="mt-8 pt-6 border-t border-gray-100 flex items-center justify-between gap-3">
                  <button 
                    onClick={() => handleToggleActive(plan)}
                    className={`flex-1 text-sm font-semibold py-2 rounded-xl border transition-colors ${plan.isActive ? 'border-gray-200 text-gray-600 hover:bg-gray-50' : 'border-green-200 text-green-600 bg-green-50 hover:bg-green-100'}`}
                  >
                    {plan.isActive ? 'Deactivate' : 'Activate'}
                  </button>
                  <button onClick={() => openEditModal(plan)} className="p-2 border border-gray-200 text-gray-600 hover:bg-gray-50 rounded-xl transition-colors">
                    <Edit2 size={18} />
                  </button>
                  <button onClick={() => handleDelete(plan.id)} className="p-2 border border-red-200 text-red-600 bg-red-50 hover:bg-red-100 rounded-xl transition-colors">
                    <Trash2 size={18} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add/Edit Modal */}
      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={editingPlan ? "Edit Plan" : "Create New Plan"}>
        <form onSubmit={handleSubmit} className="space-y-5">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Plan Name</label>
              <input type="text" required value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary" placeholder="e.g. Premium Membership" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Price (LKR)</label>
              <input type="number" required min="0" value={formData.price} onChange={e => setFormData({...formData, price: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary" placeholder="0" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Duration</label>
              <select value={formData.duration} onChange={e => setFormData({...formData, duration: e.target.value})} className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary">
                <option value="monthly">Monthly</option>
                <option value="yearly">Yearly</option>
              </select>
            </div>

            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Description (Optional)</label>
              <textarea value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} rows="2" className="w-full px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary" placeholder="Brief tagline..." />
            </div>
            
            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-2">Features</label>
              <div className="space-y-2">
                {formData.features.map((f, i) => (
                  <div key={i} className="flex gap-2">
                    <input type="text" value={f} onChange={e => handleFeatureChange(i, e.target.value)} className="flex-1 px-4 py-2 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary text-sm" placeholder="e.g. 24/7 Gym Access" />
                    {formData.features.length > 1 && (
                      <button type="button" onClick={() => removeFeature(i)} className="p-2 text-red-500 hover:bg-red-50 rounded-xl shrink-0"><Trash2 size={18}/></button>
                    )}
                  </div>
                ))}
                <button type="button" onClick={addFeature} className="text-sm font-medium text-primary hover:text-primaryDark flex items-center gap-1 mt-2">
                  <Plus size={16}/> Add another feature
                </button>
              </div>
            </div>

            <div className="col-span-2 pt-2">
              <label className="block text-sm font-medium text-gray-700 mb-2">Theme Color</label>
              <div className="flex gap-3">
                {presetColors.map(c => (
                  <button key={c} type="button" onClick={() => setFormData({...formData, color: c})} className={`w-8 h-8 rounded-full ${c} ${formData.color === c ? 'ring-2 ring-offset-2 ring-gray-900 border-2 border-white' : 'border-2 border-transparent'}`} />
                ))}
              </div>
            </div>

            <div className="col-span-2 pt-2 flex items-center justify-between">
               <label className="flex items-center gap-2 cursor-pointer">
                 <input type="checkbox" checked={formData.isPopular} onChange={e => setFormData({...formData, isPopular: e.target.checked})} className="w-4 h-4 text-primary rounded border-gray-300 focus:ring-primary" />
                 <span className="text-sm font-medium text-gray-700">Mark as Most Popular</span>
               </label>
               <label className="flex items-center gap-2 cursor-pointer">
                 <input type="checkbox" checked={formData.isActive} onChange={e => setFormData({...formData, isActive: e.target.checked})} className="w-4 h-4 text-primary rounded border-gray-300 focus:ring-primary" />
                 <span className="text-sm font-medium text-gray-700">Plan is Active</span>
               </label>
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-6 mt-6 border-t border-gray-100">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-5 py-2.5 text-gray-700 font-medium hover:bg-gray-100 rounded-xl transition-colors">Cancel</button>
            <button type="submit" className="px-5 py-2.5 bg-primary hover:bg-primaryDark text-white font-semibold rounded-xl transition-colors">Save Plan</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
