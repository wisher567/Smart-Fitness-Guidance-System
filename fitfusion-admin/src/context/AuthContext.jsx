import { createContext, useContext, useEffect, useState } from 'react';
import { 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged 
} from 'firebase/auth';
import { auth } from '../services/firebase';
import api from '../services/api';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export function AuthProvider({ children }) {
  const [user, setUser]       = useState(null);
  const [loading, setLoading] = useState(true);
  const [role, setRole]       = useState(null);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          // Verify admin role from backend
          const res = await api.get('/users/profile');
          const userRole = res.data.user?.role;
          if (userRole === 'admin' || userRole === 'trainer') {
            setUser(firebaseUser);
            setRole(userRole);
          } else {
            // Not admin or trainer - sign out
            await signOut(auth);
            setUser(null);
            setRole(null);
          }
        } catch {
          setUser(null);
          setRole(null);
        }
      } else {
        setUser(null);
        setRole(null);
      }
      setLoading(false);
    });
    return unsub;
  }, []);

  const login = async (email, password) => {
    const cred = await signInWithEmailAndPassword(auth, email, password);
    try {
      const res  = await api.get('/users/profile');
      const userRole = res.data.user?.role;
      
      if (userRole === 'admin') {
        return { role: 'admin' };
      } else if (userRole === 'trainer') {
        return { role: 'trainer' };
      } else {
        await signOut(auth);
        throw new Error('Access denied. Use the FitFusion mobile app.');
      }
    } catch(err) {
      await signOut(auth);
      throw err;
    }
  };

  const logout = () => signOut(auth);

  return (
    <AuthContext.Provider value={{ user, loading, role, isAdmin: role === 'admin', login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}
