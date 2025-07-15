import 'package:flutter/material.dart';

class UpdateNotification extends StatelessWidget {
  final VoidCallback onUpdate;
  final bool isDownloaded;

  const UpdateNotification({
    required this.onUpdate,
    required this.isDownloaded,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.system_update, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              isDownloaded
                  ? 'Обновление готово к установке'
                  : 'Доступно новое обновление',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: onUpdate,
            child: Text(
              isDownloaded ? 'УСТАНОВИТЬ' : 'ОБНОВИТЬ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
