import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/availability_service.dart';

class AvailabilityManagementScreen extends StatefulWidget {
  const AvailabilityManagementScreen({Key? key}) : super(key: key);

  @override
  _AvailabilityManagementScreenState createState() => _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState extends State<AvailabilityManagementScreen> {
  final AvailabilityService _availabilityService = AvailabilityService();
  
  Map<int, Map<String, dynamic>> _availability = {};
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _daysOfWeek = [
    {'num': 2, 'name': 'Monday'},
    {'num': 3, 'name': 'Tuesday'},
    {'num': 4, 'name': 'Wednesday'},
    {'num': 5, 'name': 'Thursday'},
    {'num': 6, 'name': 'Friday'},
    {'num': 7, 'name': 'Saturday'},
    {'num': 1, 'name': 'Sunday'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    
    try {
      final availability = await _availabilityService.getMyAvailability();
      
      setState(() {
        _availability = {};
        for (var avail in availability) {
          _availability[avail['day_of_week']] = {
            'start_time': avail['start_time'].toString().substring(0, 5),
            'end_time': avail['end_time'].toString().substring(0, 5),
            'is_available': avail['is_available'] == 1 || avail['is_available'] == true,
          };
        }
      });
    } catch (e) {
      print('Error loading availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load availability'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    
    try {
      List<Map<String, dynamic>> bulk = [];
      
      _availability.forEach((day, data) {
        bulk.add({
          'day_of_week': day,
          'start_time': '${data['start_time']}:00',
          'end_time': '${data['end_time']}:00',
          'is_available': data['is_available'],
        });
      });
      
      await _availabilityService.setBulkAvailability(bulk);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Availability saved successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadAvailability();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save availability'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _toggleDay(int dayNum) {
    setState(() {
      if (_availability.containsKey(dayNum)) {
        _availability[dayNum]!['is_available'] = !_availability[dayNum]!['is_available'];
      } else {
        _availability[dayNum] = {
          'start_time': '09:00',
          'end_time': '17:00',
          'is_available': true,
        };
      }
    });
  }

  void _updateTime(int dayNum, String type, String time) {
    setState(() {
      if (!_availability.containsKey(dayNum)) {
        _availability[dayNum] = {
          'start_time': '09:00',
          'end_time': '17:00',
          'is_available': true,
        };
      }
      _availability[dayNum]![type] = time;
    });
  }

  Future<String?> _pickTime(BuildContext context, String initialTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(initialTime.split(':')[0]),
        minute: int.parse(initialTime.split(':')[1]),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Manage Availability',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF008080),
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadAvailability,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildInfoCard(),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _daysOfWeek.length,
                    itemBuilder: (context, index) {
                      final day = _daysOfWeek[index];
                      return _buildDayCard(day);
                    },
                  ),
                ),
                _buildSaveButton(),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Set your working days and hours for patient bookings',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    final dayNum = day['num'] as int;
    final dayName = day['name'] as String;
    final hasAvailability = _availability.containsKey(dayNum);
    final isEnabled = hasAvailability && _availability[dayNum]!['is_available'];
    final startTime = _availability[dayNum]?['start_time'] ?? '09:00';
    final endTime = _availability[dayNum]?['end_time'] ?? '17:00';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEnabled ? Icons.check_circle : Icons.circle_outlined,
                  color: isEnabled ? Colors.green : Colors.grey,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dayName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (_) => _toggleDay(dayNum),
                  activeColor: Color(0xFF008080),
                ),
              ],
            ),
            if (hasAvailability) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      'From',
                      startTime,
                      () async {
                        final time = await _pickTime(context, startTime);
                        if (time != null) {
                          _updateTime(dayNum, 'start_time', time);
                        }
                      },
                      isEnabled,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector(
                      'To',
                      endTime,
                      () async {
                        final time = await _pickTime(context, endTime);
                        if (time != null) {
                          _updateTime(dayNum, 'end_time', time);
                        }
                      },
                      isEnabled,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, String time, VoidCallback onTap, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: enabled ? Color(0xFF008080) : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: enabled ? Colors.black87 : Colors.grey[500],
                  ),
                ),
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: enabled ? Color(0xFF008080) : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAll,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.save, size: 20),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Changes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
