import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/google_calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _calService = GoogleCalendarService();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _calService.addListener(_onUpdate);
    _calService.tryAutoSignIn();
  }

  @override
  void dispose() {
    _calService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _calService.events.where((e) {
      return e.start.year == day.year &&
          e.start.month == day.month &&
          e.start.day == day.day;
    }).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  void _showAddEventSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddEventSheet(
        selectedDay: _selectedDay,
        calService: _calService,
        onCreated: () {
          Navigator.pop(ctx);
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          if (!_calService.isSignedIn)
            TextButton.icon(
              onPressed: _calService.loading ? null : _calService.signIn,
              icon: const Text('G',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white)),
              label: const Text('Connect',
                  style: TextStyle(color: AppColors.primaryLight, fontSize: 13)),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.accentBlue, size: 20),
              onPressed: _calService.fetchEvents,
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventSheet,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Google Calendar status bar
          if (_calService.isSignedIn)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.accentGreen, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Synced with ${_calService.userEmail}',
                      style: const TextStyle(
                          color: AppColors.accentGreen, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _calService.signOut,
                    child: const Text('Disconnect',
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ),
                ],
              ),
            ),

          if (_calService.loading && _calService.isSignedIn)
            const LinearProgressIndicator(
              color: AppColors.accentBlue,
              backgroundColor: AppColors.surface,
              minHeight: 2,
            ),

          // Calendar widget
          Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) =>
                  setState(() => _calendarFormat = format),
              onDaySelected: (selectedDay, focusedDay) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) =>
                  setState(() => _focusedDay = focusedDay),
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                weekendTextStyle:
                    const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
                markerDecoration: const BoxDecoration(
                  color: AppColors.accentBlue,
                  shape: BoxShape.circle,
                ),
                markerSize: 5,
                markersMaxCount: 3,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: AppColors.textSecondary),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 12),
                weekendStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Selected day events
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_rounded,
                            color: AppColors.textMuted.withOpacity(0.4),
                            size: 40),
                        const SizedBox(height: 8),
                        Text(
                          isSameDay(_selectedDay, DateTime.now())
                              ? 'No events today'
                              : 'No events on ${DateFormat('MMM d').format(_selectedDay)}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _showAddEventSheet,
                          child: const Text(
                            'Tap + to add one',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) =>
                        _EventCard(event: selectedEvents[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Event Bottom Sheet ──────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  final DateTime selectedDay;
  final GoogleCalendarService calService;
  final VoidCallback onCreated;

  const _AddEventSheet({
    required this.selectedDay,
    required this.calService,
    required this.onCreated,
  });

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _allDay = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _startTime = TimeOfDay(hour: now.hour + 1, minute: 0);
    _endTime = TimeOfDay(hour: now.hour + 2, minute: 0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.card,
              dialHandColor: AppColors.primary,
              hourMinuteColor: AppColors.surface,
              hourMinuteTextColor: AppColors.textPrimary,
              dayPeriodColor: AppColors.surface,
              dayPeriodTextColor: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final day = widget.selectedDay;
    final start = _allDay
        ? DateTime(day.year, day.month, day.day)
        : DateTime(day.year, day.month, day.day, _startTime.hour, _startTime.minute);
    final end = _allDay
        ? DateTime(day.year, day.month, day.day, 23, 59)
        : DateTime(day.year, day.month, day.day, _endTime.hour, _endTime.minute);

    if (widget.calService.isSignedIn) {
      // Push to Google Calendar
      final success = await widget.calService.createEvent(
        title: _titleCtrl.text.trim(),
        start: start,
        end: end,
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create event'),
            backgroundColor: AppColors.accentRed,
          ),
        );
        setState(() => _saving = false);
        return;
      }
    } else {
      // Add locally
      widget.calService.addLocalEvent(CalendarEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        start: start,
        end: end,
        isAllDay: _allDay,
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
      ));
    }

    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                const Icon(Icons.event_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'New Event — ${DateFormat('MMM d').format(widget.selectedDay)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Event title
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Event title',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // All day toggle
            Row(
              children: [
                const Text('All day',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                const Spacer(),
                Switch.adaptive(
                  value: _allDay,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _allDay = v),
                ),
              ],
            ),

            // Time pickers
            if (!_allDay) ...[
              Row(
                children: [
                  Expanded(
                    child: _TimePicker(
                      label: 'Start',
                      time: _startTime,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePicker(
                      label: 'End',
                      time: _endTime,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Location
            TextField(
              controller: _locationCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Location (optional)',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: AppColors.textMuted, size: 18),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Notes (optional)',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.notes_rounded,
                    color: AppColors.textMuted, size: 18),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        widget.calService.isSignedIn
                            ? 'Create & Sync to Google'
                            : 'Create Event',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded,
                color: AppColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  const _EventCard({required this.event});

  Color get _eventColor {
    switch (event.colorId) {
      case '1': return const Color(0xFF7986CB);
      case '2': return const Color(0xFF33B679);
      case '3': return const Color(0xFF8E24AA);
      case '4': return const Color(0xFFE67C73);
      case '5': return const Color(0xFFF6BF26);
      case '6': return const Color(0xFFFF8A65);
      case '7': return AppColors.accentBlue;
      case '9': return AppColors.accentBlue;
      case '10': return AppColors.accentGreen;
      case '11': return const Color(0xFFD50000);
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _eventColor;
    final timeStr = event.isAllDay
        ? 'All day'
        : '${DateFormat.jm().format(event.start)} – ${DateFormat.jm().format(event.end)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(timeStr,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (event.location != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Flexible(
                  child: Text(event.location!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12))),
            ]),
          ],
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(event.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12, height: 1.4)),
          ],
        ],
      ),
    );
  }
}
