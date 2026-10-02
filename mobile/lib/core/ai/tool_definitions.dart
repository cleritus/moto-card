/// JSON Schemas for Claude's tool-calling — 1:1 with the app's own REST API
/// (see [AiToolExecutor] for the execution side). Full v1 set: vehicles,
/// fuel logs, service logs, reminders — create/read/update/delete plus
/// reminder complete/incomplete.
const List<Map<String, dynamic>> kAiTools = [
  // --- Vehicles ---
  {
    'name': 'list_vehicles',
    'description':
        'Zwraca listę pojazdów użytkownika (id, nazwa, marka, model, rok, '
            'przebieg, nr rejestracyjny). Wywołaj to najpierw, jeśli user '
            'nie podał, o który pojazd chodzi.',
    'input_schema': {
      'type': 'object',
      'properties': <String, dynamic>{},
    },
  },
  {
    'name': 'get_vehicle',
    'description': 'Zwraca szczegóły jednego pojazdu.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
      },
      'required': ['vehicleId'],
    },
  },
  {
    'name': 'add_vehicle',
    'description': 'Dodaje nowy pojazd do garażu.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': 'Własna nazwa pojazdu.'},
        'make': {'type': 'string', 'description': 'Marka, np. Honda.'},
        'vehicleModel': {'type': 'string', 'description': 'Model, np. CBR1000R.'},
        'year': {'type': 'integer'},
        'licensePlate': {'type': 'string'},
        'mileage': {'type': 'integer'},
        'engineCapacity': {
          'type': 'integer',
          'description': 'Pojemność silnika w cm³, np. 1584.',
        },
        'vin': {'type': 'string'},
        'purchaseDate': {'type': 'string', 'description': 'Format YYYY-MM-DD.'},
        'notes': {'type': 'string'},
      },
      'required': ['name', 'make', 'vehicleModel', 'year', 'licensePlate'],
    },
  },
  {
    'name': 'update_vehicle',
    'description':
        'Zmienia wybrane pola istniejącego pojazdu. Podaj tylko pola, które '
            'się zmieniają.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'name': {'type': 'string'},
        'make': {'type': 'string'},
        'vehicleModel': {'type': 'string'},
        'year': {'type': 'integer'},
        'licensePlate': {'type': 'string'},
        'mileage': {'type': 'integer'},
        'engineCapacity': {
          'type': 'integer',
          'description': 'Pojemność silnika w cm³, np. 1584.',
        },
        'vin': {'type': 'string'},
        'purchaseDate': {'type': 'string', 'description': 'Format YYYY-MM-DD.'},
        'notes': {'type': 'string'},
      },
      'required': ['vehicleId'],
    },
  },
  {
    'name': 'delete_vehicle',
    'description':
        'Usuwa pojazd razem z całą jego historią (tankowania, serwisy, '
            'przypomnienia). Nieodwracalne.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
      },
      'required': ['vehicleId'],
    },
  },

  // --- Fuel logs ---
  {
    'name': 'list_fuel_logs',
    'description': 'Zwraca listę tankowań dla pojazdu.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'page': {'type': 'integer'},
        'limit': {'type': 'integer'},
      },
      'required': ['vehicleId'],
    },
  },
  {
    'name': 'get_fuel_log',
    'description': 'Zwraca szczegóły jednego wpisu tankowania.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'fuelLogId': {'type': 'string'},
      },
      'required': ['vehicleId', 'fuelLogId'],
    },
  },
  {
    'name': 'add_fuel_log',
    'description': 'Dodaje wpis tankowania dla wskazanego pojazdu.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string', 'description': 'ID pojazdu, z list_vehicles.'},
        'mileage': {'type': 'integer', 'description': 'Przebieg w km w momencie tankowania.'},
        'fuelAmount': {'type': 'number', 'description': 'Ilość zatankowanego paliwa w litrach.'},
        'totalCost': {'type': 'number', 'description': 'Całkowity koszt tankowania w złotych.'},
        'date': {
          'type': 'string',
          'description':
              'Data tankowania w formacie YYYY-MM-DD. Pomiń, jeśli user nie '
                  'podał — wtedy przyjmowana jest dzisiejsza data.',
        },
        'notes': {'type': 'string', 'description': 'Opcjonalna notatka.'},
      },
      'required': ['vehicleId', 'mileage', 'fuelAmount', 'totalCost'],
    },
  },
  {
    'name': 'update_fuel_log',
    'description':
        'Zmienia wybrane pola istniejącego wpisu tankowania. Podaj tylko '
            'pola, które się zmieniają.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'fuelLogId': {'type': 'string'},
        'mileage': {'type': 'integer'},
        'fuelAmount': {'type': 'number'},
        'totalCost': {'type': 'number'},
        'date': {'type': 'string', 'description': 'Format YYYY-MM-DD.'},
        'notes': {'type': 'string'},
      },
      'required': ['vehicleId', 'fuelLogId'],
    },
  },
  {
    'name': 'delete_fuel_log',
    'description': 'Usuwa wpis tankowania. Nieodwracalne.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'fuelLogId': {'type': 'string'},
      },
      'required': ['vehicleId', 'fuelLogId'],
    },
  },

  // --- Service logs ---
  {
    'name': 'list_service_logs',
    'description': 'Zwraca listę wpisów serwisowych dla pojazdu.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'page': {'type': 'integer'},
        'limit': {'type': 'integer'},
      },
      'required': ['vehicleId'],
    },
  },
  {
    'name': 'get_service_log',
    'description': 'Zwraca szczegóły jednego wpisu serwisowego.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'serviceLogId': {'type': 'string'},
      },
      'required': ['vehicleId', 'serviceLogId'],
    },
  },
  {
    'name': 'add_service_log',
    'description': 'Dodaje wpis serwisowy (np. wymiana oleju, przegląd).',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'mileage': {'type': 'integer', 'description': 'Przebieg w km w momencie serwisu.'},
        'serviceType': {'type': 'string', 'description': 'Rodzaj serwisu, np. "Wymiana oleju".'},
        'date': {
          'type': 'string',
          'description': 'Format YYYY-MM-DD. Pomiń — domyślnie dzisiaj.',
        },
        'totalCost': {'type': 'number'},
        'description': {'type': 'string'},
        'mechanic': {'type': 'string', 'description': 'Warsztat/mechanik.'},
        'notes': {'type': 'string'},
      },
      'required': ['vehicleId', 'mileage', 'serviceType'],
    },
  },
  {
    'name': 'update_service_log',
    'description':
        'Zmienia wybrane pola istniejącego wpisu serwisowego. Podaj tylko '
            'pola, które się zmieniają.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'serviceLogId': {'type': 'string'},
        'mileage': {'type': 'integer'},
        'serviceType': {'type': 'string'},
        'date': {'type': 'string', 'description': 'Format YYYY-MM-DD.'},
        'totalCost': {'type': 'number'},
        'description': {'type': 'string'},
        'mechanic': {'type': 'string'},
        'notes': {'type': 'string'},
      },
      'required': ['vehicleId', 'serviceLogId'],
    },
  },
  {
    'name': 'delete_service_log',
    'description': 'Usuwa wpis serwisowy. Nieodwracalne.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'serviceLogId': {'type': 'string'},
      },
      'required': ['vehicleId', 'serviceLogId'],
    },
  },

  // --- Reminders ---
  {
    'name': 'list_reminders',
    'description': 'Zwraca listę przypomnień dla pojazdu.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'filter': {
          'type': 'string',
          'enum': ['active', 'completed', 'all'],
          'description': 'Domyślnie "active".',
        },
        'page': {'type': 'integer'},
        'limit': {'type': 'integer'},
      },
      'required': ['vehicleId'],
    },
  },
  {
    'name': 'get_reminder',
    'description': 'Zwraca szczegóły jednego przypomnienia.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'reminderId': {'type': 'string'},
      },
      'required': ['vehicleId', 'reminderId'],
    },
  },
  {
    'name': 'add_reminder',
    'description':
        'Dodaje przypomnienie. Dla type="date" WYMAGANE jest dueDate, dla '
            'type="mileage" WYMAGANY jest dueMileage — jeśli brakuje '
            'właściwego pola, dopytaj usera zamiast zgadywać.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'title': {'type': 'string'},
        'type': {'type': 'string', 'enum': ['date', 'mileage']},
        'dueDate': {
          'type': 'string',
          'description': 'Format YYYY-MM-DD. Wymagane, gdy type="date".',
        },
        'dueMileage': {
          'type': 'integer',
          'description': 'Przebieg w km. Wymagane, gdy type="mileage".',
        },
        'intervalKm': {
          'type': 'integer',
          'description': 'Interwał cykliczny w km (opcjonalny, dla przypomnień przebiegowych).',
        },
        'lastDoneMileage': {'type': 'integer'},
        'notes': {'type': 'string'},
      },
      'required': ['vehicleId', 'title', 'type'],
    },
  },
  {
    'name': 'update_reminder',
    'description':
        'Zmienia wybrane pola istniejącego przypomnienia. Podaj tylko pola, '
            'które się zmieniają.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'reminderId': {'type': 'string'},
        'title': {'type': 'string'},
        'type': {'type': 'string', 'enum': ['date', 'mileage']},
        'dueDate': {'type': 'string', 'description': 'Format YYYY-MM-DD.'},
        'dueMileage': {'type': 'integer'},
        'intervalKm': {'type': 'integer'},
        'lastDoneMileage': {'type': 'integer'},
        'notes': {'type': 'string'},
      },
      'required': ['vehicleId', 'reminderId'],
    },
  },
  {
    'name': 'delete_reminder',
    'description': 'Usuwa przypomnienie. Nieodwracalne.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'reminderId': {'type': 'string'},
      },
      'required': ['vehicleId', 'reminderId'],
    },
  },
  {
    'name': 'complete_reminder',
    'description': 'Oznacza przypomnienie jako wykonane.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'reminderId': {'type': 'string'},
      },
      'required': ['vehicleId', 'reminderId'],
    },
  },
  {
    'name': 'incomplete_reminder',
    'description': 'Cofa oznaczenie przypomnienia jako wykonane.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'vehicleId': {'type': 'string'},
        'reminderId': {'type': 'string'},
      },
      'required': ['vehicleId', 'reminderId'],
    },
  },
];
