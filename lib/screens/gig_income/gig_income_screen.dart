import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/gig_job.dart';
import '../../services/firestore_service.dart';

class GigIncomeScreen extends StatefulWidget {
  const GigIncomeScreen({super.key});
  @override
  State<GigIncomeScreen> createState() => _GigIncomeScreenState();
}

class _GigIncomeScreenState extends State<GigIncomeScreen> {
  final FirestoreService _fs = FirestoreService();
  final _platforms = const ['DoorDash','Uber Eats','Instacart','Amazon Flex','Spark','Lyft','Uber','Other'];
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: StreamBuilder<List<GigJob>>(
        stream: _fs.streamGigJobs(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final jobs = snap.data!;
          final totalEarn = jobs.fold<double>(0.0, (s,j)=>s+j.earnings);
          final totalExp = jobs.fold<double>(0.0, (s,j)=>s+j.expenses);
          final totalMin = jobs.fold<int>(0, (s,j)=>s+j.minutes);
          final totalMiles = jobs.fold<double>(0.0, (s,j)=>s+j.miles);
          final net = totalEarn - totalExp;
          final perHr = totalMin>0? net/(totalMin/60) : 0.0;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('💼 Gig Income', style: TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:Colors.white)),
              Text('${jobs.length} jobs • Net \$${net.toStringAsFixed(0)} • ${totalMiles.toStringAsFixed(1)} mi • \$${perHr.toStringAsFixed(2)}/hr', style: const TextStyle(color: Colors.grey, fontSize:12)),
              const SizedBox(height:12),
              Row(children:[_stat('Net', '\$${net.toStringAsFixed(0)}', Colors.tealAccent), const SizedBox(width:8), _stat('\$/hr', '\$${perHr.toStringAsFixed(2)}', Colors.green)]),
              const SizedBox(height:8),
              Row(children:[_stat('Earn', '\$${totalEarn.toStringAsFixed(0)}', Colors.white), const SizedBox(width:8), _stat('Miles', '${totalMiles.toStringAsFixed(1)}', Colors.orange)]),
              const SizedBox(height:16),
              ElevatedButton.icon(onPressed: ()=>_showForm(), icon: const Icon(Icons.add, color: Colors.black), label: const Text('Add Gig Job', style: TextStyle(color: Colors.black)), style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent[700])),
              const SizedBox(height:16),
              if (jobs.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Text('No gigs yet. Add one!', style: TextStyle(color: Colors.grey)))
              else
            ...jobs.map((j)=>Container(margin: const EdgeInsets.symmetric(vertical:6), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)), child: Row(children:[Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('${j.platform} • \$${j.earnings.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text('${DateFormat('MMM dd').format(j.date)} • ${j.miles.toStringAsFixed(1)} mi • ${j.minutes} min • Net \$${j.net.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize:12)), if (j.notes.isNotEmpty) Text(j.notes, style: const TextStyle(color: Colors.white70, fontSize:11))])), IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size:18), onPressed: ()=>_showForm(existing: j)), IconButton(icon: const Icon(Icons.delete, color: Colors.red, size:18), onPressed: ()=>_confirmDelete(j))]))),
            ],
          );
        },
      ),
    );
  }
  Widget _stat(String label, String val, Color color){ return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical:12), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(60))), child: Column(children:[Text(label, style: const TextStyle(color: Colors.grey, fontSize:11)), const SizedBox(height:4), Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold))]))); }
  void _confirmDelete(GigJob j){ showDialog(context: context, builder: (ctx)=>AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: const Text('Delete?', style: TextStyle(color: Colors.white)), content: Text('Delete ${j.platform} \$${j.earnings}?', style: const TextStyle(color: Colors.grey)), actions:[TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))), TextButton(onPressed: () async { await _fs.deleteGigJob(j.id); if(context.mounted) Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red)))])); }
  void _showForm({GigJob? existing}){
    final earnCtrl = TextEditingController(text: existing?.earnings.toString()?? '');
    final milesCtrl = TextEditingController(text: existing?.miles.toString()?? '');
    final expCtrl = TextEditingController(text: existing?.expenses.toString()?? '');
    final minCtrl = TextEditingController(text: existing?.minutes.toString()?? '');
    final notesCtrl = TextEditingController(text: existing?.notes?? '');
    String platform = existing?.platform?? 'DoorDash';
    DateTime date = existing?.date?? DateTime.now();
    final bool isEdit = existing!= null;
    final String editId = existing?.id?? '';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx)=>DraggableScrollableSheet(initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.5, expand: false, builder: (c, sc)=>Container(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: SingleChildScrollView(controller: sc, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Center(child: Container(width:40,height:4,decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height:16),
      Text(isEdit? 'Edit Gig' : 'Add Gig Job', style: const TextStyle(color: Colors.white, fontSize:20, fontWeight: FontWeight.bold)),
      const SizedBox(height:16),
      DropdownButtonFormField<String>(initialValue: platform, dropdownColor: const Color(0xFF2C2C2C), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Platform', labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder()), items: _platforms.map((p)=>DropdownMenuItem(value:p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(), onChanged: (v){ if(v!=null) platform=v; }),
      const SizedBox(height:12),
      GestureDetector(onTap: () async { final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2023), lastDate: DateTime.now()); if(picked!=null) setState(()=> date=picked); }, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(color: Colors.white)), const Icon(Icons.calendar_today, color: Colors.grey, size:18)]))),
      const SizedBox(height:12),
      TextField(controller: earnCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Earnings \$ *', labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller: milesCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Miles', labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller: expCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Expenses (gas) \$', labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller: minCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Minutes', labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder())),
      const SizedBox(height:12),
      TextField(controller: notesCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Notes', labelStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder())),
      const SizedBox(height:20),
      SizedBox(width: double.infinity, height:50, child: ElevatedButton(onPressed: () async {
        final earn = double.tryParse(earnCtrl.text.trim())?? 0;
        if(earn<=0){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter earnings'), backgroundColor: Colors.red)); return; }
        final job = GigJob(id: isEdit? editId : DateTime.now().millisecondsSinceEpoch.toString(), platform: platform, date: date, earnings: earn, miles: double.tryParse(milesCtrl.text.trim())?? 0, expenses: double.tryParse(expCtrl.text.trim())?? 0, minutes: int.tryParse(minCtrl.text.trim())?? 0, notes: notesCtrl.text.trim());
        await _fs.saveGigJob(job);
        if(mounted) Navigator.pop(context);
      }, style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent[700]), child: Text(isEdit? 'Update' : 'Save', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
    ])),
    )));
  }
}
