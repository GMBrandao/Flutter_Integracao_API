import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      routes: {
        '/equipamentos': (context) => EquipamentosPage(),
        '/cadastro-equipamento': (context) => CadastroEquipamentoPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu')),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text('Consultar Equipamentos'),
              onTap: () {
                Navigator.pushNamed(context, '/equipamentos');
              },
            ),
            ListTile(
              title: Text('Cadastrar Equipamento'),
              onTap: () {
                Navigator.pushNamed(context, '/cadastro-equipamento');
              },
            ),
          ],
        ),
      ),
      body: Center(child: Text('Bem-vindo ao Sistema de Equipamentos!')),
    );
  }
}

class EquipamentosPage extends StatefulWidget {
  @override
  _EquipamentosPageState createState() => _EquipamentosPageState();
}

class _EquipamentosPageState extends State<EquipamentosPage> {
  List<dynamic> equipamentos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEquipamentos();
  }

  Future<void> fetchEquipamentos() async {
    try {
      final response = await http.get(Uri.parse(
          'https://app-web-uniara-example-60f73cc06c77.herokuapp.com/equipamentos'));

      if (response.statusCode == 200) {
        setState(() {
          equipamentos = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar equipamentos');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  Future<void> reservarEquipamento(int equipamentoId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://app-web-uniara-example-60f73cc06c77.herokuapp.com/equipamentos/$equipamentoId/reservar'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          final index =
              equipamentos.indexWhere((e) => e['id'] == equipamentoId);
          if (index != -1) {
            equipamentos[index]['disponivel'] = false;
            equipamentos[index]['dataRetirada'] = DateTime.now().toString();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Equipamento reservado com sucesso!'),
        ));
      } else {
        throw Exception('Falha ao reservar equipamento');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao reservar equipamento'),
      ));
    }
  }

  Future<void> liberarEquipamento(int equipamentoId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://app-web-uniara-example-60f73cc06c77.herokuapp.com/equipamentos/$equipamentoId/liberar'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          final index =
              equipamentos.indexWhere((e) => e['id'] == equipamentoId);
          if (index != -1) {
            equipamentos[index]['disponivel'] = true;
            equipamentos[index]['dataRetirada'] = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reserva liberada com sucesso!'),
        ));
      } else {
        throw Exception('Falha ao liberar reserva');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao liberar reserva'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Equipamentos')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: equipamentos.length,
              itemBuilder: (context, index) {
                final equipamento = equipamentos[index];
                return ListTile(
                  title: Text(equipamento['nome']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(equipamento['disponivel']
                          ? 'Disponível'
                          : 'Reservado'),
                      if (equipamento['dataRetirada'] != null)
                        Text('Retirado em: ${equipamento['dataRetirada']}'),
                    ],
                  ),
                  trailing: equipamento['disponivel']
                      ? ElevatedButton(
                          onPressed: () {
                            reservarEquipamento(equipamento['id']);
                          },
                          child: Text('Reservar'),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            liberarEquipamento(equipamento['id']);
                          },
                          child: Text('Liberar'),
                        ),
                );
              },
            ),
    );
  }
}

class CadastroEquipamentoPage extends StatefulWidget {
  @override
  _CadastroEquipamentoPageState createState() =>
      _CadastroEquipamentoPageState();
}

class _CadastroEquipamentoPageState extends State<CadastroEquipamentoPage> {
  final _formKey = GlobalKey<FormState>();
  String nome = '';
  bool disponivel = true;

  Future<void> cadastrarEquipamento() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final response = await http.post(
          Uri.parse(
              'https://app-web-uniara-example-60f73cc06c77.herokuapp.com/equipamentos'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "nome": nome,
            "disponivel": disponivel,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Equipamento cadastrado com sucesso!'),
          ));
          Navigator.pop(context);
        } else {
          throw Exception('Falha ao cadastrar equipamento');
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao cadastrar equipamento'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Equipamentos')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nome do Equipamento'),
                onSaved: (value) => nome = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o nome';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: Text('Disponível'),
                value: disponivel,
                onChanged: (bool value) {
                  setState(() {
                    disponivel = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: cadastrarEquipamento,
                child: Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
