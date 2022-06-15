import { MigrationInterface, QueryRunner, Table } from 'typeorm';

export class createUsers1655323152164 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'users',
        columns: [
          {
            name: 'id',
            isPrimary: true,
            type: 'string',
          },
          {
            name: 'username',
            isPrimary: false,
            type: 'string',
          },
        ],
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('users');
  }
}
