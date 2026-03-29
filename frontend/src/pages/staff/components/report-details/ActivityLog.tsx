interface ActivityLogProps {
  historyItems: { title: string; date: string; by: string }[];
}

export default function ActivityLog({ historyItems }: ActivityLogProps) {
  return (
    <section className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-surface-container/50">
      <h3 className="text-xs font-bold text-outline uppercase tracking-widest px-1 mb-6">Lịch sử hoạt động</h3>
      <div className="space-y-6 pl-2 border-l-2 border-surface-container">
        {historyItems.map((item, idx) => {
          const isLast = idx === historyItems.length - 1;
          return (
            <div className="relative" key={idx}>
              <div className={`absolute -left-[17px] top-0 w-4 h-4 rounded-full border-4 border-surface shadow-sm ${isLast ? 'bg-primary' : 'bg-surface-container-highest'}`}></div>
              <div className={`pl-6 ${isLast ? 'opacity-100' : 'opacity-60'}`}>
                <p className="text-sm font-bold text-on-surface">{item.title}</p>
                <p className="text-[11px] text-outline mt-1 font-medium">
                  {new Date(item.date).toLocaleString()} • bởi {item.by}
                </p>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
