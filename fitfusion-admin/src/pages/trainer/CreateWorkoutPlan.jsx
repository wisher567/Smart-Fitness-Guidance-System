import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { 
  ArrowLeft, Plus, Trash2, Save, 
  Dumbbell, Flame, Clock, Search, 
  CheckCircle2, X
} from 'lucide-react';
import api from '../../services/api';
import Avatar from '../../components/ui/Avatar';
import Button from '../../components/ui/Button';
import LoadingSpinner from '../../components/ui/LoadingSpinner';
import { toast } from 'react-hot-toast';

const COMMON_EXERCISES = [
  { name: 'Squats', muscleGroup: 'Legs', calories: 12 },
  { name: 'Push-ups', muscleGroup: 'Chest', calories: 8 },
  { name: 'Pull-ups', muscleGroup: 'Back', calories: 15 },
  { name: 'Lunges', muscleGroup: 'Legs', calories: 10 },
  { name: 'Plank', muscleGroup: 'Core', calories: 5 },
  { name: 'Deadlifts', muscleGroup: 'Full Body', calories: 20 },
  { name: 'Bench Press', muscleGroup: 'Chest', calories: 12 },
  { name: 'Shoulder Press', muscleGroup: 'Shoulders', calories: 10 },
  { name: 'Bicep Curls', muscleGroup: 'Arms', calories: 6 },
  { name: 'Tricep Dips', muscleGroup: 'Arms', calories: 8 },
  { name: 'Mountain Climbers', muscleGroup: 'Cardio', calories: 10 },
  { name: 'Burpees', muscleGroup: 'Full Body', calories: 15 },
];

export default function CreateWorkoutPlan() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const preSelectedClient = searchParams.get('client');

  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [clients, setClients] = useState([]);
  const [showExercisePicker, setShowExercisePicker] = useState(false);
  
  // Form State
  const [formData, setFormData] = useState({
    selectedClient: preSelectedClient || '',
    planName: '',
    notes: '',
    targetDate: '',
    exercises: []
  });

  useEffect(() => {
    fetchClients();
  }, []);

  const fetchClients = async () => {
    try {
      const res = await api.get('/trainer/clients');
      if (res.data.success) {
        setClients(res.data.clients);
      }
    } catch (err) {
      console.error('Failed to fetch trainer clients:', err);
    } finally {
      setLoading(false);
    }
  };

  const addExercise = (ex) => {
    const newEx = {
      id: Math.random().toString(36).substr(2, 9),
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      sets: 3,
      reps: '12',
      rest: '60 seconds',
      estimatedCalories: ex.calories || 10,
      notes: ''
    };
    setFormData({ ...formData, exercises: [...formData.exercises, newEx] });
    setShowExercisePicker(false);
  };

  const removeExercise = (id) => {
    setFormData({ ...formData, exercises: formData.exercises.filter(e => e.id !== id) });
  };

  const updateExercise = (id, field, value) => {
    setFormData({
      ...formData,
      exercises: formData.exercises.map(e => e.id === id ? { ...e, [field]: value } : e)
    });
  };

  const handleSubmit = async (e, isDraft = false) => {
    e.preventDefault();
    if (!formData.selectedClient || !formData.planName || formData.exercises.length === 0) {
      toast.error('Please fill in all required fields and add at least one exercise.');
      return;
    }

    setSubmitting(true);
    try {
      const payload = {
        clientUid: formData.selectedClient,
        planName: formData.planName,
        notes: formData.notes,
        targetDate: formData.targetDate,
        exercises: formData.exercises,
        status: isDraft ? 'draft' : 'assigned'
      };

      const res = await api.post('/trainer/plans', payload);
      if (res.data.success) {
        toast.success(isDraft ? 'Plan saved as draft' : 'Plan assigned to client successfully!');
        navigate('/trainer/plans');
      }
    } catch (err) {
      console.error('Failed to save plan:', err);
      toast.error(err.response?.data?.error || 'Failed to save workout plan');
    } finally {
      setSubmitting(false);
    }
  };

  const totalCalories = formData.exercises.reduce((s, e) => s + (parseInt(e.estimatedCalories) || 0), 0);
  const totalDuration = formData.exercises.length * 5; // Rough estimate: 5 mins per exercise

  if (loading) return <LoadingSpinner />;

  return (
    <div className="space-y-6 animate-fade-in max-w-5xl mx-auto pb-20">
      {/* Header */}
      <div className="flex items-center justify-between">
        <button 
          onClick={() => navigate('/trainer/plans')}
          className="flex items-center gap-2 text-gray-500 hover:text-[#E8845C] transition-colors"
        >
          <ArrowLeft size={18} />
          <span className="text-sm font-semibold">Back to Plans</span>
        </button>
        <div className="flex gap-3">
           <Button 
            variant="secondary" 
            className="rounded-2xl bg-white border-gray-100"
            onClick={(e) => handleSubmit(e, true)}
            disabled={submitting}
           >
              Save as Draft
           </Button>
           <Button 
            variant="primary" 
            className="rounded-2xl shadow-lg shadow-orange-500/20 px-8"
            onClick={(e) => handleSubmit(e, false)}
            disabled={submitting}
           >
              {submitting ? 'Assigning...' : 'Assign to Client'}
           </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Form Area */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50 space-y-6">
            <h2 className="text-xl font-bold text-gray-900 px-1 border-l-4 border-orange-500 pl-4">Plan Details</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <label className="text-xs font-bold text-gray-400 uppercase tracking-widest px-1">Selected Client</label>
                <select 
                  className="w-full bg-gray-50 border border-gray-100 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 transition-all font-medium text-sm"
                  value={formData.selectedClient}
                  onChange={(e) => setFormData({...formData, selectedClient: e.target.value})}
                >
                  <option value="">Choose a client...</option>
                  {clients.map(c => (
                    <option key={c.uid} value={c.uid}>{c.name}</option>
                  ))}
                </select>
              </div>
              <div className="space-y-2">
                <label className="text-xs font-bold text-gray-400 uppercase tracking-widest px-1">Plan Name</label>
                <input 
                  type="text"
                  placeholder="e.g. Morning Strength Protocol"
                  className="w-full bg-gray-50 border border-gray-100 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 transition-all font-medium text-sm"
                  value={formData.planName}
                  onChange={(e) => setFormData({...formData, planName: e.target.value})}
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
               <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-400 uppercase tracking-widest px-1">Target Date (Optional)</label>
                  <input 
                    type="date"
                    className="w-full bg-gray-50 border border-gray-100 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 transition-all font-medium text-sm"
                    value={formData.targetDate}
                    onChange={(e) => setFormData({...formData, targetDate: e.target.value})}
                  />
               </div>
               <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-400 uppercase tracking-widest px-1">Notes / Instructions</label>
                  <input 
                    type="text"
                    placeholder="General tips for the workout..."
                    className="w-full bg-gray-50 border border-gray-100 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 transition-all font-medium text-sm"
                    value={formData.notes}
                    onChange={(e) => setFormData({...formData, notes: e.target.value})}
                  />
               </div>
            </div>
          </div>

          {/* Exercise Builder */}
          <div className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50 space-y-6">
            <div className="flex items-center justify-between px-1">
               <h2 className="text-xl font-bold text-gray-900 border-l-4 border-orange-500 pl-4">Exercises ({formData.exercises.length})</h2>
               <Button 
                variant="outline" 
                className="rounded-xl gap-2 border-gray-200 text-sm py-2"
                onClick={() => setShowExercisePicker(true)}
               >
                  <Plus size={16} />
                  Add Exercise
               </Button>
            </div>

            {formData.exercises.length > 0 ? (
              <div className="space-y-4">
                {formData.exercises.map((ex, index) => (
                  <div key={ex.id} className="bg-gray-50/50 rounded-2xl p-5 border border-gray-100 group hover:border-[#E8845C]/20 transition-all">
                    <div className="flex justify-between items-start mb-4">
                      <div className="flex items-center gap-3">
                         <div className="w-8 h-8 rounded-lg bg-orange-100 text-[#E8845C] flex items-center justify-center font-bold text-sm">
                            {index + 1}
                         </div>
                         <div>
                            <h4 className="font-bold text-gray-900">{ex.name}</h4>
                            <p className="text-[10px] text-gray-400 uppercase font-bold tracking-widest">{ex.muscleGroup}</p>
                         </div>
                      </div>
                      <button onClick={() => removeExercise(ex.id)} className="text-gray-300 hover:text-red-500 transition-colors p-1">
                         <Trash2 size={16} />
                      </button>
                    </div>

                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                       <div className="space-y-1">
                          <label className="text-[10px] font-bold text-gray-400 uppercase tracking-tighter">Sets</label>
                          <input 
                            type="number"
                            className="w-full bg-white border border-gray-100 rounded-lg px-3 py-1.5 text-xs font-bold focus:outline-none focus:border-[#E8845C]"
                            value={ex.sets}
                            onChange={(e) => updateExercise(ex.id, 'sets', e.target.value)}
                          />
                       </div>
                       <div className="space-y-1">
                          <label className="text-[10px] font-bold text-gray-400 uppercase tracking-tighter">Reps / Duration</label>
                          <input 
                            type="text"
                            className="w-full bg-white border border-gray-100 rounded-lg px-3 py-1.5 text-xs font-bold focus:outline-none focus:border-[#E8845C]"
                            value={ex.reps}
                            onChange={(e) => updateExercise(ex.id, 'reps', e.target.value)}
                          />
                       </div>
                       <div className="space-y-1">
                          <label className="text-[10px] font-bold text-gray-400 uppercase tracking-tighter">Rest Period</label>
                          <input 
                            type="text"
                            className="w-full bg-white border border-gray-100 rounded-lg px-3 py-1.5 text-xs font-bold focus:outline-none focus:border-[#E8845C]"
                            value={ex.rest}
                            onChange={(e) => updateExercise(ex.id, 'rest', e.target.value)}
                          />
                       </div>
                       <div className="space-y-1">
                          <label className="text-[10px] font-bold text-gray-400 uppercase tracking-tighter">Calories</label>
                          <input 
                            type="number"
                            className="w-full bg-white border border-gray-100 rounded-lg px-3 py-1.5 text-xs font-bold focus:outline-none focus:border-[#E8845C]"
                            value={ex.estimatedCalories}
                            onChange={(e) => updateExercise(ex.id, 'estimatedCalories', e.target.value)}
                          />
                       </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="bg-gray-50/50 rounded-3xl p-16 border-2 border-dashed border-gray-100 text-center flex flex-col items-center justify-center gap-4">
                 <Dumbbell size={32} className="text-gray-200" />
                 <p className="text-gray-400 text-sm font-medium italic">Click "Add Exercise" to start building your workout.</p>
              </div>
            )}
          </div>
        </div>

        {/* Plan Summary Sidebar */}
        <div className="space-y-6">
           <div className="bg-[#0F1923] p-8 rounded-3xl text-white shadow-xl flex flex-col gap-6 relative overflow-hidden">
              <div className="relative z-10">
                <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
                   <div className="bg-[#E8845C] w-1.5 h-6 rounded-full"></div>
                   Plan Summary
                </h3>

                <div className="space-y-6">
                   <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-2xl bg-white/5 flex items-center justify-center border border-white/5">
                         <CheckCircle2 className="text-[#E8845C]" size={22} />
                      </div>
                      <div>
                         <p className="text-[10px] text-[#64748B] uppercase font-black tracking-widest">Total Exercises</p>
                         <p className="text-2xl font-black">{formData.exercises.length}</p>
                      </div>
                   </div>

                   <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-2xl bg-white/5 flex items-center justify-center border border-white/5">
                         <Flame className="text-orange-400" size={22} />
                      </div>
                      <div>
                         <p className="text-[10px] text-[#64748B] uppercase font-black tracking-widest">Total Energy</p>
                         <div className="flex items-baseline gap-1">
                           <p className="text-2xl font-black">{totalCalories}</p>
                           <p className="text-xs font-bold text-[#64748B]">kCal</p>
                         </div>
                      </div>
                   </div>

                   <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-2xl bg-white/5 flex items-center justify-center border border-white/5">
                         <Clock className="text-blue-400" size={22} />
                      </div>
                      <div>
                         <p className="text-[10px] text-[#64748B] uppercase font-black tracking-widest">Est. Duration</p>
                         <div className="flex items-baseline gap-1">
                           <p className="text-2xl font-black">~{totalDuration}</p>
                           <p className="text-xs font-bold text-[#64748B]">mins</p>
                         </div>
                      </div>
                   </div>
                </div>

                <div className="mt-8 pt-8 border-t border-white/5">
                   <p className="text-[10px] text-[#64748B] uppercase font-black tracking-widest mb-3">Muscle Groups Involved</p>
                   <div className="flex flex-wrap gap-2">
                      {Array.from(new Set(formData.exercises.map(e => e.muscleGroup))).map((mg, i) => (
                        <span key={i} className="text-[10px] font-bold px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 uppercase tracking-tighter">
                          {mg}
                        </span>
                      ))}
                   </div>
                </div>
              </div>

              {/* Decorative circle */}
              <div className="absolute top-0 right-0 w-32 h-32 bg-orange-500/10 rounded-full blur-3xl -mr-16 -mt-16"></div>
           </div>

           <div className="bg-white p-6 rounded-3xl shadow-sm border border-gray-50 italic">
              <p className="text-xs text-gray-500 leading-relaxed font-medium">
                Tip: Adding notes to individual exercises helps clients maintain proper form during training.
              </p>
           </div>
        </div>
      </div>

      {/* Exercise Picker Modal */}
      {showExercisePicker && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
           <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => setShowExercisePicker(false)}></div>
           <div className="bg-white w-full max-w-lg rounded-[2.5rem] shadow-2xl relative z-10 overflow-hidden animate-scale-up">
              <div className="p-8">
                 <div className="flex justify-between items-center mb-6">
                    <div>
                       <h3 className="text-2xl font-black text-gray-900 leading-tight">Pick an Exercise</h3>
                       <p className="text-sm text-gray-500 font-medium">Choose from common gym workouts</p>
                    </div>
                    <button onClick={() => setShowExercisePicker(false)} className="p-2 hover:bg-gray-100 rounded-full transition-all">
                       <X className="text-gray-400" size={24} />
                    </button>
                 </div>

                 <div className="relative mb-6">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                    <input 
                      type="text"
                      placeholder="Search exercises..."
                      className="w-full pl-11 pr-4 py-3 bg-gray-50 border border-gray-100 rounded-2xl focus:outline-none focus:ring-2 focus:ring-[#E8845C]/20 transition-all text-sm font-medium"
                    />
                 </div>

                 <div className="max-h-[350px] overflow-y-auto space-y-2 pr-2 scrollbar-thin">
                    {COMMON_EXERCISES.map((ex, i) => (
                      <button 
                        key={i}
                        onClick={() => addExercise(ex)}
                        className="w-full flex items-center justify-between p-4 rounded-3xl hover:bg-orange-50 group transition-all text-left"
                      >
                         <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-white rounded-2xl shadow-sm flex items-center justify-center group-hover:shadow-orange-200 transition-all">
                               <Dumbbell size={20} className="text-gray-400 group-hover:text-[#E8845C]" />
                            </div>
                            <div>
                               <p className="font-bold text-gray-900 leading-tight">{ex.name}</p>
                               <p className="text-[10px] text-gray-400 uppercase font-bold tracking-widest">{ex.muscleGroup}</p>
                            </div>
                         </div>
                         <Plus size={18} className="text-gray-300 group-hover:text-[#E8845C] group-hover:scale-125 transition-all" />
                      </button>
                    ))}
                 </div>
              </div>
           </div>
        </div>
      )}
    </div>
  );
}
