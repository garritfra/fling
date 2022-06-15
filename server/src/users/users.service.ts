import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { CreateUserInput } from './dto/create-user.input';
import { UpdateUserInput } from './dto/update-user.input';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  users: User[] = [];

  create(createUserInput: CreateUserInput): User {
    const newUser = {
      id: randomUUID(),
      username: createUserInput.username,
    };
    this.users.push(newUser);

    return newUser;
  }

  findAll(): User[] {
    return this.users;
  }

  findOne(id: string): User | null {
    return this.users.find((user: User) => user.id === id);
  }

  update(id: string, updateUserInput: UpdateUserInput): User | null {
    const index = this.users.findIndex((user) => user.id === id);

    if (index) {
      this.users[index] = {
        ...this.users[index],
        ...updateUserInput,
      };
      return this.users[index];
    }

    return null;
  }

  remove(id: string): User | null {
    const removedUser = this.users.find((user) => user.id === id);
    if (removedUser) {
      this.users = this.users.filter((user) => user.id !== id);
      return removedUser;
    }

    return null;
  }
}
