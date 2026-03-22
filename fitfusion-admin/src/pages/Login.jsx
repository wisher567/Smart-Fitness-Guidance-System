import React, { useState } from 'react';
import { Mail, Lock, Eye, EyeOff, AlertCircle, ArrowRight } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { toast } from 'react-hot-toast';
import { useAuth } from '../context/AuthContext';

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const result = await login(email, password);
      // Route based on role
      if (result?.role === 'trainer') {
        navigate('/trainer/dashboard');
      } else {
        navigate('/dashboard');
      }
    } catch (err) {
      setError(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex">
      {/* Left panel - branding */}
      <div className="hidden lg:flex w-1/2 bg-[#0F1923] flex-col 
        justify-between p-12 relative overflow-hidden">
        
        {/* Background decoration */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute -top-40 -right-40 w-96 h-96 
            bg-[#E8845C]/10 rounded-full blur-3xl" />
          <div className="absolute -bottom-40 -left-40 w-96 h-96 
            bg-[#E8845C]/5 rounded-full blur-3xl" />
        </div>

        {/* Logo */}
        <div className="relative flex items-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-white flex items-center justify-center shadow-xl shadow-orange-500/10 p-1">
            <img src="/logo.png" alt="FitFusion" className="w-full h-full object-contain" />
          </div>
          <div>
            <p className="text-white font-bold text-xl leading-none">FitFusion</p>
            <p className="text-[#475569] text-xs mt-0.5">Gym Management</p>
          </div>
        </div>

        {/* Center content */}
        <div className="relative">
          <h1 className="text-5xl font-bold text-white leading-tight mb-6">
            Manage your gym<br />
            <span className="text-[#E8845C]">smarter</span>, not harder.
          </h1>
          <p className="text-[#64748B] text-lg leading-relaxed max-w-md">
            Complete control over members, payments, classes 
            and equipment — all in one place.
          </p>
          
          {/* Feature list */}
          <div className="mt-10 space-y-3">
            {[
              '📊 Real-time member analytics',
              '💳 Payment & subscription management', 
              '📅 Class scheduling & enrollment',
              '🤖 AI-powered member insights',
            ].map(f => (
              <div key={f} className="flex items-center gap-3">
                <div className="w-1.5 h-1.5 rounded-full bg-[#E8845C]" />
                <p className="text-[#94A3B8] text-sm">{f}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Bottom stats */}
        <div className="relative grid grid-cols-3 gap-4">
          {[
            { value: '500+', label: 'Members' },
            { value: 'LKR 840K', label: 'Revenue' },
            { value: '98%', label: 'Satisfaction' },
          ].map(stat => (
            <div key={stat.label} className="bg-white/5 rounded-2xl p-4 
              border border-white/10 backdrop-blur-sm">
              <p className="text-white font-bold text-xl">{stat.value}</p>
              <p className="text-[#64748B] text-xs mt-1">{stat.label}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Right panel - login form */}
      <div className="flex-1 flex items-center justify-center p-8 
        bg-[#F8FAFC]">
        <div className="w-full max-w-md animate-fade-in">
          
          {/* Mobile logo */}
          <div className="lg:hidden flex items-center gap-3 mb-8">
            <div className="w-12 h-12 rounded-2xl bg-white flex items-center justify-center shadow-lg shadow-orange-500/10 p-1 border border-gray-100">
              <img src="/logo.png" alt="FitFusion" className="w-full h-full object-contain" />
            </div>
            <span className="text-gray-900 font-bold text-xl">FitFusion</span>
          </div>

          <div className="bg-white rounded-3xl shadow-card p-8 
            border border-[#E2E8F0]">
            
            <div className="mb-8">
              <h2 className="text-2xl font-bold text-gray-900">Welcome back</h2>
              <p className="text-gray-500 text-sm mt-1">
                Sign in to your admin portal
              </p>
            </div>

            {error && (
              <div className="mb-6 p-4 bg-red-50 border border-red-100 
                rounded-2xl flex items-start gap-3 animate-slide-up">
                <AlertCircle size={16} className="text-red-500 mt-0.5 shrink-0" />
                <p className="text-red-600 text-sm">{error}</p>
              </div>
            )}

            <form onSubmit={handleLogin} className="space-y-4">
              
              {/* Email field */}
              <div>
                <label className="text-sm font-medium text-gray-700 
                  block mb-1.5">
                  Email address
                </label>
                <div className="relative">
                  <Mail size={16} className="absolute left-4 top-1/2 
                    -translate-y-1/2 text-gray-400" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    placeholder="admin@fitfusion.com"
                    className="w-full pl-11 pr-4 py-3 bg-gray-50 
                      border border-gray-200 rounded-2xl text-sm
                      text-gray-900 placeholder-gray-400
                      focus:outline-none focus:ring-2 
                      focus:ring-[#E8845C]/30 focus:border-[#E8845C]
                      transition-all"
                  />
                </div>
              </div>

              {/* Password field */}
              <div>
                <label className="text-sm font-medium text-gray-700 
                  block mb-1.5">
                  Password
                </label>
                <div className="relative">
                  <Lock size={16} className="absolute left-4 top-1/2 
                    -translate-y-1/2 text-gray-400" />
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    placeholder="Enter your password"
                    className="w-full pl-11 pr-12 py-3 bg-gray-50 
                      border border-gray-200 rounded-2xl text-sm
                      text-gray-900 placeholder-gray-400
                      focus:outline-none focus:ring-2 
                      focus:ring-[#E8845C]/30 focus:border-[#E8845C]
                      transition-all"
                  />
                  <button type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2
                      text-gray-400 hover:text-gray-600 transition-colors">
                    {showPassword ? <EyeOff size={16}/> : <Eye size={16}/>}
                  </button>
                </div>
              </div>

              {/* Submit button */}
              <button
                type="submit"
                disabled={loading}
                className="w-full py-3 bg-gradient-to-r from-[#E8845C] 
                  to-[#D4673A] text-white font-semibold rounded-2xl
                  shadow-button hover:shadow-lg hover:-translate-y-0.5
                  active:translate-y-0 transition-all duration-200
                  disabled:opacity-60 disabled:cursor-not-allowed
                  disabled:transform-none flex items-center justify-center gap-2 mt-2">
                {loading ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white/30 
                      border-t-white rounded-full animate-spin" />
                    Signing in...
                  </>
                ) : (
                  <>
                    Sign In
                    <ArrowRight size={16} />
                  </>
                )}
              </button>

            </form>

            <p className="text-center text-gray-400 text-xs mt-6">
              Member? Download the 
              <span className="text-[#E8845C] font-medium cursor-pointer hover:underline"> FitFusion App</span>
            </p>

          </div>

          <p className="text-center text-gray-400 text-xs mt-4">
            © {new Date().getFullYear()} FitFusion Gym Management System
          </p>
        </div>
      </div>
    </div>
  );
}
