import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';
import 'event_attendees.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../date_time_picker.dart';
import 'event_reminders.dart';

enum RecurrenceRuleEndType { Indefinite, MaxOccurrences, SpecifiedEndDate }

class CalendarEventPage extends StatefulWidget {
  final Calendar _calendar;
  final Event _event;

  CalendarEventPage(this._calendar, [this._event]);

  @override
  _CalendarEventPageState createState() {
    return _CalendarEventPageState(_calendar, _event);
  }
}

class _CalendarEventPageState extends State<CalendarEventPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Calendar _calendar;

  Event _event;
  DeviceCalendarPlugin _deviceCalendarPlugin;

  DateTime _startDate;
  TimeOfDay _startTime;

  DateTime _endDate;
  TimeOfDay _endTime;

  bool _autovalidate = false;
  bool _isRecurringEvent = false;
  bool _isByDayOfMonth = false;
  RecurrenceRuleEndType _recurrenceRuleEndType;

  List<DayOfTheWeek> _daysOfTheWeek = List<DayOfTheWeek>();
  List<int> _daysOfTheMonth = List<int>();
  List<int> _monthsOfTheYear = List<int>();
  List<int> _setPositions = List<int>();
  List<int> _validDaysOfTheMonth = List<int>();
  List<int> _validMonthsOfTheYear = List<int>();
  List<int> _validWeeksOfTheYear = List<int>();
  List<Attendee> _attendees = List<Attendee>();
  List<Reminder> _reminders = List<Reminder>();
  int _totalOccurrences;
  int _interval;
  DayOfTheWeek _selectedDayPos = DayOfTheWeek.Monday;
  DateTime _recurrenceEndDate;

  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.Daily;

  _CalendarEventPageState(this._calendar, this._event) {
    _deviceCalendarPlugin = DeviceCalendarPlugin();

    for (var i = 1; i <= 12; i++) {
      _validMonthsOfTheYear.add(i);
    }
    for (var i = -53; i <= -1; i++) {
      _validWeeksOfTheYear.add(i);
    }
    for (var i = 1; i <= 53; i++) {
      _validWeeksOfTheYear.add(i);
    }
    _attendees = List<Attendee>();
    _reminders = List<Reminder>();
    _recurrenceRuleEndType = RecurrenceRuleEndType.Indefinite;

    if (this._event == null) {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(Duration(hours: 1));
      _event = Event(this._calendar.id, start: _startDate, end: _endDate);
      _recurrenceEndDate = _endDate;
      _monthsOfTheYear.add(MonthOfTheYear.January.value);
      _daysOfTheMonth = [1];
    } else {
      _startDate = _event.start;
      _endDate = _event.end;
      _isRecurringEvent = _event.recurrenceRule != null;
      if (_event.attendees.isNotEmpty) {
        _attendees.addAll(_event.attendees);
      }
      if (_event.reminders.isNotEmpty) {
        _reminders.addAll(_event.reminders);
      }
      if (_isRecurringEvent) {
        _interval = _event.recurrenceRule.interval;
        _totalOccurrences = _event.recurrenceRule.totalOccurrences;
        _recurrenceFrequency = _event.recurrenceRule.recurrenceFrequency;
        if (_totalOccurrences != null) {
          _recurrenceRuleEndType = RecurrenceRuleEndType.MaxOccurrences;
        }
        if (_event.recurrenceRule.endDate != null) {
          _recurrenceRuleEndType = RecurrenceRuleEndType.SpecifiedEndDate;
          _recurrenceEndDate = _event.recurrenceRule.endDate;
        }

        _isByDayOfMonth = _event.recurrenceRule.setPositions == null;
        _daysOfTheWeek = _event.recurrenceRule.daysOfTheWeek ?? List<DayOfTheWeek>();

        if (_recurrenceFrequency == RecurrenceFrequency.Monthly || _recurrenceFrequency == RecurrenceFrequency.Yearly) {
          _monthsOfTheYear = _event.recurrenceRule.monthsOfTheYear ?? List<int>();

          if (!_isByDayOfMonth) {
            _setPositions = _event.recurrenceRule.setPositions ?? List<int>();
            _selectedDayPos = _daysOfTheWeek?.first ?? DayOfTheWeek.Monday;
          }
          else {
            _daysOfTheMonth = _event.recurrenceRule.daysOfTheMonth ?? List<int>();
          }
        }
      }
    }

    _startTime = TimeOfDay(hour: _startDate.hour, minute: _startDate.minute);
    _endTime = TimeOfDay(hour: _endDate.hour, minute: _endDate.minute);    

    // Getting days of the current month (or a selected month for the yearly recurrence) as a default
    _getValidDaysOfMonth(_recurrenceFrequency);
  }

  void printAttendeeDetails(Attendee attendee) {
    print(
        'attendee name: ${attendee.name}, email address: ${attendee.emailAddress}');
    print(
        'ios specifics - status: ${attendee.iosAttendeeDetails?.attendanceStatus}, role:  ${attendee.iosAttendeeDetails?.role}');
    print(
        'android specifics - status ${attendee.androidAttendeeDetails?.attendanceStatus}, is required: ${attendee.androidAttendeeDetails?.isRequired}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_event.eventId?.isEmpty ?? true
            ? 'Create event'
            : 'Edit event ${_event.title}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Form(
              autovalidate: _autovalidate,
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      key: Key('titleField'),
                      initialValue: _event.title,
                      decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Meeting with Gloria...'),
                      validator: _validateTitle,
                      onSaved: (String value) {
                        _event.title = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      initialValue: _event.description,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Remember to buy flowers...'),
                      onSaved: (String value) {
                        _event.description = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      initialValue: _event.location,
                      decoration: const InputDecoration(
                          labelText: 'Location', hintText: 'Sydney, Australia'),
                      onSaved: (String value) {
                        _event.location = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      initialValue: _event.url?.data?.contentText ?? '',
                      decoration: const InputDecoration(
                          labelText: 'URL',
                          hintText: 'https://google.com'),
                      onSaved: (String value) {
                        var uri = Uri.dataFromString(value);
                        _event.url = uri;
                      },
                    ),
                  ),
                  SwitchListTile(
                      value: _event.allDay,
                      onChanged: (value) => setState(() => _event.allDay = value),
                      title: Text('All Day'),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: DateTimePicker(
                      labelText: 'From',
                      enableTime: !_event.allDay,
                      selectedDate: _startDate,
                      selectedTime: _startTime,
                      selectDate: (DateTime date) {
                        setState(() {
                          _startDate = date;
                          _event.start = _combineDateWithTime(_startDate, _startTime);
                        });
                      },
                      selectTime: (TimeOfDay time) {
                        setState(() {
                            _startTime = time;
                            _event.start = _combineDateWithTime(_startDate, _startTime);
                          },
                        );
                      },
                    ),
                  ),
                  if (!_event.allDay) ... [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: DateTimePicker(
                        labelText: 'To',
                        selectedDate: _endDate,
                        selectedTime: _endTime,
                        selectDate: (DateTime date) {
                          setState(
                            () {
                              _endDate = date;
                              _event.end =
                                  _combineDateWithTime(_endDate, _endTime);
                            },
                          );
                        },
                        selectTime: (TimeOfDay time) {
                          setState(
                            () {
                              _endTime = time;
                              _event.end =
                                  _combineDateWithTime(_endDate, _endTime);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: () async {
                      List<Attendee> result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EventAttendeesPage(_attendees)));
                      if (result == null) {
                        return;
                      }
                      _attendees = result;
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10.0,
                          children: [
                            Icon(Icons.people),
                            if (_attendees.isEmpty) Text('Add people'),
                            for (var attendee in _attendees)
                              Text('${attendee.emailAddress};')
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      List<Reminder> result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EventRemindersPage(_reminders)));
                      if (result == null) {
                        return;
                      }
                      _reminders = result;
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10.0,
                          children: [
                            Icon(Icons.alarm),
                            if (_reminders.isEmpty) Text('Add reminders'),
                            for (var reminder in _reminders)
                              Text('${reminder.minutes} minutes before; ')
                          ],
                        ),
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    value: _isRecurringEvent,
                    title: Text('Is recurring'),
                    onChanged: (isChecked) {
                      setState(() {
                        _isRecurringEvent = isChecked;
                      });
                    },
                  ),
                  if (_isRecurringEvent) ...[
                    ListTile(
                      leading: Text('Select a Recurrence Type'),
                      trailing: DropdownButton<RecurrenceFrequency>(
                        onChanged: (selectedFrequency) {
                          setState(() {
                            _recurrenceFrequency = selectedFrequency;
                            _getValidDaysOfMonth(_recurrenceFrequency);
                          });
                        },
                        value: _recurrenceFrequency,
                        items: RecurrenceFrequency.values
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: _recurrenceFrequencyToText(f),
                                ))
                            .toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                      child: Row(
                        children: <Widget>[
                          Text('Repeat Every '),
                          Flexible(
                            child: TextFormField(
                              initialValue: _interval?.toString() ?? '1',
                              decoration: const InputDecoration(hintText: '1'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                WhitelistingTextInputFormatter.digitsOnly, 
                                LengthLimitingTextInputFormatter(2)
                              ],
                              validator: _validateInterval,
                              textAlign: TextAlign.right,
                              onSaved: (String value) {
                                _interval = int.tryParse(value);
                              },
                            ),
                          ),
                          _recurrenceFrequencyToIntervalText(_recurrenceFrequency),
                        ],
                      ),
                    ),
                    if (_recurrenceFrequency == RecurrenceFrequency.Weekly) ... [
                      Column(
                          children: [ 
                            ...DayOfTheWeek.values.map((d) {
                              return CheckboxListTile(
                                title: Text(_enumToString(d)),
                                value: _daysOfTheWeek?.any((dow) => dow == d) ?? false,
                                onChanged: (selected) {
                                  setState(() {
                                    if (selected) _daysOfTheWeek.add(d);
                                    else _daysOfTheWeek.remove(d);
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      )
                    ],
                    if (_recurrenceFrequency == RecurrenceFrequency.Monthly || _recurrenceFrequency == RecurrenceFrequency.Yearly) ...[
                      SwitchListTile(
                        value: _isByDayOfMonth,
                        onChanged: (value) => setState(() => _isByDayOfMonth = value),
                        title: Text('By day of the month'),
                      )
                    ],
                    if (_recurrenceFrequency == RecurrenceFrequency.Yearly && _isByDayOfMonth) ...[
                      ListTile(
                        leading: Text('Month of the year'),
                        trailing: DropdownButton<MonthOfTheYear>(
                          onChanged: (value) {
                            setState(() {
                              _monthsOfTheYear.clear();
                              _monthsOfTheYear.add(value.value);
                              _getValidDaysOfMonth(_recurrenceFrequency);
                            });
                          },
                          value: _monthsOfTheYear.isEmpty ? null : _monthsOfTheYear.first.getMonthEnumValue,
                          items: MonthOfTheYear.values
                            .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(_enumToString(m)),
                            )).toList(),
                        ),
                      ),
                    ],
                    if (_isByDayOfMonth && (_recurrenceFrequency == RecurrenceFrequency.Monthly || _recurrenceFrequency == RecurrenceFrequency.Yearly)) ...[
                      ListTile(
                        leading: Text('Day of the month'),
                        trailing: DropdownButton<int>(
                          onChanged: (value) {
                            setState(() {
                              _daysOfTheMonth.clear();
                              _daysOfTheMonth.add(value);
                            });
                          },
                          value: _daysOfTheMonth.isEmpty ? null : _daysOfTheMonth[0],
                          items: _validDaysOfTheMonth
                            .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.toString()),
                            )).toList(),
                        ),
                      ),
                    ],
                    if (!_isByDayOfMonth && (_recurrenceFrequency == RecurrenceFrequency.Monthly || _recurrenceFrequency == RecurrenceFrequency.Yearly)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_recurrenceFrequencyToText(_recurrenceFrequency).data + ' on the ')
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: DropdownButton<FirstToLastPosition>(
                                onChanged: (value) { 
                                  setState(() { 
                                    _setPositions.clear();
                                    _setPositions.add(value.value);
                                  });
                                },
                                value: _setPositions.isEmpty ? FirstToLastPosition.First : _setPositions.first.getSetPosEnumValue,
                                items: FirstToLastPosition.values
                                  .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(_enumToString(d)),
                                  )).toList(),
                              ),
                            ),
                            Flexible(
                              child: DropdownButton<DayOfTheWeek>(
                                onChanged: (value) { setState(() { _selectedDayPos = value; }); },
                                value: DayOfTheWeek.values[_selectedDayPos.index],
                                items: DayOfTheWeek.values
                                  .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(_enumToString(d)),
                                  )).toList(),
                              ),
                            ),
                            Text('of'),
                            if (_recurrenceFrequency == RecurrenceFrequency.Monthly) ... [
                              Text(_enumToString(DateTime.now().month.getMonthEnumValue)),
                            ],
                            if (_recurrenceFrequency == RecurrenceFrequency.Yearly) ... [
                              Flexible(
                                child: DropdownButton<MonthOfTheYear>(
                                  onChanged: (value) {
                                    setState(() {
                                      _monthsOfTheYear.clear();
                                      _monthsOfTheYear.add(value.value);
                                    });
                                  },
                                  value: _monthsOfTheYear.isEmpty ? null : _monthsOfTheYear.first.getMonthEnumValue,
                                  items: MonthOfTheYear.values
                                    .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(_enumToString(m)),
                                    )).toList(),
                                  ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                    ListTile(
                      leading: Text('Event ends'),
                      trailing: DropdownButton<RecurrenceRuleEndType>(
                        onChanged: (value) {
                          setState(() {
                            _recurrenceRuleEndType = value;
                          });
                        },
                        value: _recurrenceRuleEndType,
                        items: RecurrenceRuleEndType.values
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: _recurrenceRuleEndTypeToText(f),
                                ))
                            .toList(),
                      ),
                    ),
                    if (_recurrenceRuleEndType == RecurrenceRuleEndType.MaxOccurrences)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                        child: Row(
                          children: <Widget>[
                            Text('For the next '),
                            Flexible(
                              child: TextFormField(
                                initialValue: _totalOccurrences?.toString() ?? '1',
                                decoration: const InputDecoration(hintText: '1'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  WhitelistingTextInputFormatter.digitsOnly, 
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                validator: _validateTotalOccurrences,
                                textAlign: TextAlign.right,
                                onSaved: (String value) {
                                  _totalOccurrences = int.tryParse(value);
                                },
                              ),
                            ),
                            Text(' occurrences'),
                          ],
                        ),
                      ),
                    if (_recurrenceRuleEndType == RecurrenceRuleEndType.SpecifiedEndDate)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: DateTimePicker(
                          labelText: 'Date',
                          enableTime: false,
                          selectedDate: _recurrenceEndDate,
                          selectDate: (DateTime date) {
                            setState(() {
                              _recurrenceEndDate = date;
                            });
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (_event.eventId?.isNotEmpty ?? false)
              RaisedButton(
                key: Key('deleteEventButton'),
                textColor: Colors.white,
                color: Colors.red,
                child: Text('Delete'),
                onPressed: () async {
                  await _deviceCalendarPlugin.deleteEvent(
                      _calendar.id, _event.eventId);
                  Navigator.pop(context, true);
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: Key('saveEventButton'),
        onPressed: () async {
          final FormState form = _formKey.currentState;
          if (!form.validate()) {
            _autovalidate = true; // Start validating on every change.
            showInSnackBar('Please fix the errors in red before submitting.');
          } else {
            form.save();
            if (_isRecurringEvent) {
              if (!_isByDayOfMonth && (_recurrenceFrequency == RecurrenceFrequency.Monthly || _recurrenceFrequency == RecurrenceFrequency.Yearly)) {
                // Setting day of the week parameters for SetPos to avoid clashing with the weekly recurrence values
                _daysOfTheWeek.clear();
                _daysOfTheWeek.add(_selectedDayPos);
              }
              else _setPositions.clear();

              _event.recurrenceRule = RecurrenceRule(_recurrenceFrequency,
                  interval: _interval,
                  totalOccurrences: _totalOccurrences,
                  endDate: _recurrenceRuleEndType == RecurrenceRuleEndType.SpecifiedEndDate ? _recurrenceEndDate : null,
                  daysOfTheWeek: _daysOfTheWeek,
                  daysOfTheMonth: _daysOfTheMonth,
                  monthsOfTheYear: _monthsOfTheYear,
                  setPositions: _setPositions);
            }
            _event.attendees = _attendees;
            _event.reminders = _reminders;
            var createEventResult =
                await _deviceCalendarPlugin.createOrUpdateEvent(_event);
            if (createEventResult.isSuccess) {
              Navigator.pop(context, true);
            } else {
              showInSnackBar(createEventResult.errorMessages.join(' | '));
            }
          }
        },
        child: Icon(Icons.check),
      ),
    );
  }

  Text _recurrenceFrequencyToText(RecurrenceFrequency recurrenceFrequency) {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.Daily:
        return Text('Daily');
      case RecurrenceFrequency.Weekly:
        return Text('Weekly');
      case RecurrenceFrequency.Monthly:
        return Text('Monthly');
      case RecurrenceFrequency.Yearly:
        return Text('Yearly');
      default:
        return Text('');
    }
  }

  Text _recurrenceFrequencyToIntervalText(RecurrenceFrequency recurrenceFrequency) {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.Daily:
        return Text(' Day(s)');
      case RecurrenceFrequency.Weekly:
        return Text(' Week(s) on');
      case RecurrenceFrequency.Monthly:
        return Text(' Month(s)');
      case RecurrenceFrequency.Yearly:
        return Text(' Year(s)');
      default:
        return Text('');
    }
  }

  Text _recurrenceRuleEndTypeToText(RecurrenceRuleEndType endType) {
    switch (endType) {
      case RecurrenceRuleEndType.Indefinite:
        return Text('Indefinitely');
      case RecurrenceRuleEndType.MaxOccurrences:
        return Text('After a set number of times');
      case RecurrenceRuleEndType.SpecifiedEndDate:
        return Text('Continues until a specified date');
      default:
        return Text('');
    }
  }

  // Get total days of a month
  void _getValidDaysOfMonth(RecurrenceFrequency frequency) {
    _validDaysOfTheMonth.clear();
    var totalDays = 0;

    // Year frequency: Get total days of the selected month
    if (_monthsOfTheYear.isNotEmpty && frequency == RecurrenceFrequency.Yearly) {
      totalDays = DateTime(new DateTime.now().year, _monthsOfTheYear.isEmpty ? 1 : _monthsOfTheYear[0] + 1, 0).day;
    }
    else { // Otherwise, get total days of the current month
      var now = new DateTime.now();
      totalDays = DateTime(now.year, now.month + 1, 0).day;
    }

    for (var i = 1; i <= totalDays; i++) {
      _validDaysOfTheMonth.add(i);
    }
  }

  String _validateTotalOccurrences(String value) {
    if (value.isNotEmpty && int.tryParse(value) == null) {
      return 'Total occurrences needs to be a valid number';
    }
    return null;
  }

  String _validateInterval(String value) {
    if (value.isNotEmpty && int.tryParse(value) == null) {
      return 'Interval needs to be a valid number';
    }
    return null;
  }

  String _validateTitle(String value) {
    if (value.isEmpty) {
      return 'Name is required.';
    }

    return null;
  }

  DateTime _combineDateWithTime(DateTime date, TimeOfDay time) {
    if (date == null && time == null) {
      return null;
    }
    final dateWithoutTime =
        DateTime.parse(DateFormat("y-MM-dd 00:00:00").format(date));
    return dateWithoutTime
        .add(Duration(hours: time.hour, minutes: time.minute));
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(value)));
  }

  String _enumToString(Object enumValue) {
    return enumValue.toString().split('.').last;
  }
}
