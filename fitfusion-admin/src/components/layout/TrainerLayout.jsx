import { Outlet } from 'react-router-dom';
import TrainerSidebar from './TrainerSidebar';
import Header from './Header';

export default function TrainerLayout() {
  return (
    <div className="flex h-screen bg-[#F8FAFC] overflow-hidden">
      <TrainerSidebar />
      <div className="flex-1 flex flex-col lg:ml-[260px] overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
