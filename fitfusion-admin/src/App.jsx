import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider, useAuth } from './context/AuthContext';
import Layout from './components/layout/Layout';
import TrainerLayout from './components/layout/TrainerLayout';

// Mock components so App compiles before we write pages
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Members from './pages/Members';
import MemberDetail from './pages/MemberDetail';
import Payments from './pages/Payments';
import Plans from './pages/Plans';
import Classes from './pages/Classes';
import Equipment from './pages/Equipment';
import Trainers from './pages/Trainers';
import Reports from './pages/Reports';
import Settings from './pages/Settings';
import TrainerRequests from './pages/TrainerRequests';
import Messages from './pages/Messages';

// Trainer Pages
import TrainerDashboard from './pages/trainer/TrainerDashboard';
import TrainerClients from './pages/trainer/TrainerClients';
import TrainerClientDetail from './pages/trainer/TrainerClientDetail';
import TrainerWorkoutPlans from './pages/trainer/TrainerWorkoutPlans';
import CreateWorkoutPlan from './pages/trainer/CreateWorkoutPlan';
import TrainerClasses from './pages/trainer/TrainerClasses';
import TrainerChat from './pages/trainer/TrainerChat';
import TrainerProfile from './pages/trainer/TrainerProfile';

const ProtectedRoute = ({ children, allowedRoles }) => {
  const { user, role, loading } = useAuth();
  if (loading) return (
    <div className="flex items-center justify-center h-screen bg-[#F8F9FA]">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
    </div>
  );
  if (!user) return <Navigate to="/login" replace />;
  if (allowedRoles && !allowedRoles.includes(role)) {
    return <Navigate to="/login" replace />;
  }
  return children;
};

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Toaster position="top-right" toastOptions={{
          style: { borderRadius: '12px', fontSize: '14px' },
          success: { iconTheme: { primary: '#7CB342', secondary: 'white' } },
          error:   { iconTheme: { primary: '#E53935', secondary: 'white' } },
        }} />
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={
            <ProtectedRoute allowedRoles={['admin']}>
              <Layout />
            </ProtectedRoute>
          }>
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard"  element={<Dashboard />} />
            <Route path="members"    element={<Members />} />
            <Route path="members/:uid" element={<MemberDetail />} />
            <Route path="payments"   element={<Payments />} />
            <Route path="plans"      element={<Plans />} />
            <Route path="classes"    element={<Classes />} />
            <Route path="equipment"  element={<Equipment />} />
            <Route path="trainers"   element={<Trainers />} />
            <Route path="trainer-requests" element={<TrainerRequests />} />
            <Route path="reports"    element={<Reports />} />
            <Route path="messages"   element={<Messages />} />
            <Route path="settings"   element={<Settings />} />
          </Route>

          {/* Trainer Routes */}
          <Route path="/trainer" element={
            <ProtectedRoute allowedRoles={['trainer', 'admin']}>
              <TrainerLayout />
            </ProtectedRoute>
          }>
            <Route index element={<Navigate to="/trainer/dashboard" replace />} />
            <Route path="dashboard"  element={<TrainerDashboard />} />
            <Route path="clients"    element={<TrainerClients />} />
            <Route path="clients/:uid" element={<TrainerClientDetail />} />
            <Route path="plans"      element={<TrainerWorkoutPlans />} />
            <Route path="plans/create" element={<CreateWorkoutPlan />} />
            <Route path="classes"    element={<TrainerClasses />} />
            <Route path="chat"       element={<TrainerChat />} />
            <Route path="profile"    element={<TrainerProfile />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
